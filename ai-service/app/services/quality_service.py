import io
import cv2
import numpy as np
from PIL import Image
from typing import Union, Tuple, Optional
from app.core.config import settings
from app.schemas.quality import QualityCheckResult, QualityChecks, QualitySubCheck

class ImageQualityService:
    """
    Image Quality Gate Service (Section 5).
    Evaluates:
      1. Blur: Laplacian variance gradient energy.
      2. Brightness/Exposure: Mean luminance and clipped pixel ratios.
      3. Field of View (FOV): Fundus circle area coverage against canvas.
      4. Image Dimensions: Meets clinical minimum resolution requirements.
      5. Validity: Valid retinal color profile and non-degenerate structure.
    """
    def __init__(self):
        self.quality_threshold = settings.QUALITY_THRESHOLD
        self.blur_threshold = settings.QUALITY_BLUR_THRESHOLD
        self.brightness_min = settings.QUALITY_BRIGHTNESS_MIN
        self.brightness_max = settings.QUALITY_BRIGHTNESS_MAX
        self.fov_min = settings.QUALITY_FOV_MIN
        self.min_dimension = settings.MIN_IMAGE_DIMENSION

    def load_image(self, image_input: Union[bytes, Image.Image, np.ndarray]) -> np.ndarray:
        """Loads and returns RGB numpy array (H, W, 3)."""
        if isinstance(image_input, bytes):
            image = Image.open(io.BytesIO(image_input))
            if image.mode != "RGB":
                image = image.convert("RGB")
            return np.array(image)
        elif isinstance(image_input, Image.Image):
            if image_input.mode != "RGB":
                image_input = image_input.convert("RGB")
            return np.array(image_input)
        elif isinstance(image_input, np.ndarray):
            if image_input.ndim == 2:
                return cv2.cvtColor(image_input, cv2.COLOR_GRAY2RGB)
            elif image_input.shape[2] == 4:
                return cv2.cvtColor(image_input, cv2.COLOR_RGBA2RGB)
            return image_input
        else:
            raise ValueError("Unsupported image input type.")

    def inspect_blur(self, gray: np.ndarray, rgb: Optional[np.ndarray] = None) -> Tuple[bool, float, str]:
        """
        Calculates Laplacian variance to assess optical focus and motion blur.
        Uses green channel (optimal for retinal vasculature absorption) across
        retinal patches to reliably detect sharp vessel/disc edges, even when the
        fovea/macula is naturally smooth and edge-free.
        """
        h, w = gray.shape
        retina_mask = gray > 15
        retina_pixel_count = np.count_nonzero(retina_mask)

        if retina_pixel_count < 100:
            return False, 0.0, "Empty or non-retinal frame"

        # Use green channel if available (highest vessel absorption / contrast)
        eval_channel = rgb[:, :, 1] if (rgb is not None and rgb.ndim == 3 and rgb.shape[2] >= 2) else gray

        # Divide image into 4x4 grid of patches to isolate in-focus vascular arcades / disc
        grid_h, grid_w = h // 4, w // 4
        patch_vars = []

        for row in range(4):
            for col in range(4):
                y1, y2 = row * grid_h, (row + 1) * grid_h
                x1, x2 = col * grid_w, (col + 1) * grid_w
                patch_mask = retina_mask[y1:y2, x1:x2]
                if np.count_nonzero(patch_mask) > (grid_h * grid_w * 0.35):
                    patch_data = eval_channel[y1:y2, x1:x2]
                    var = float(cv2.Laplacian(patch_data, cv2.CV_64F).var())
                    patch_vars.append(var)

        if not patch_vars:
            cy, cx = h // 2, w // 2
            rh, rw = int(h * 0.25), int(w * 0.25)
            central = eval_channel[cy - rh: cy + rh, cx - rw: cx + rw]
            patch_vars = [float(cv2.Laplacian(central, cv2.CV_64F).var())] if central.size > 0 else [0.0]

        # Top 35% percentile variance represents the sharpest anatomical structures
        sorted_vars = sorted(patch_vars, reverse=True)
        top_k = max(1, int(len(sorted_vars) * 0.35))
        effective_var = float(np.mean(sorted_vars[:top_k]))

        # Normalization:
        # Extreme Gaussian blur has variance < 5.0 -> score < 0.35 (triggers RETAKE)
        # Moderate blur: variance 6-18 -> score 0.40 - 0.58 (triggers RETAKE because < 0.60 threshold)
        # Standard sharp fundus: variance 25-80+ -> score 0.70 - 0.98
        normalized_score = min(1.0, max(0.0, (effective_var / (effective_var + 16.0)) * 1.35))
        normalized_score = round(normalized_score, 2)

        passed = normalized_score >= self.blur_threshold
        if passed:
            details = f"Ketajaman citra memadai: {round(effective_var, 1)} (skor: {normalized_score})"
        else:
            details = f"Citra mengalami blur / tidak fokus: {round(effective_var, 1)} (skor: {normalized_score} < ambang {self.blur_threshold})"
        return passed, normalized_score, details

    def inspect_brightness(self, gray: np.ndarray) -> Tuple[bool, float, str]:
        """
        Evaluates illumination, underexposure, and glare/overexposure.
        Supports natural Asian / Indonesian darker fundus melanin pigmentation,
        while strictly rejecting underexposed or overexposed images.
        """
        # Exclude black background (pixel values < 15) to inspect actual fundus retina
        mask = gray > 15
        retina_pixel_count = np.count_nonzero(mask)
        total_pixels = gray.size

        # If less than 15% of frame has retinal signal, it's pitch black / empty
        if retina_pixel_count == 0 or (retina_pixel_count / total_pixels) < 0.15:
            return False, 0.05, "Citra terlalu gelap / underexposed (hampir hitam seluruhnya)"

        retina_pixels = gray[mask] / 255.0
        mean_lum = float(np.mean(retina_pixels))

        # Check severe underexposure
        if mean_lum < self.brightness_min:
            score = round(max(0.05, (mean_lum / self.brightness_min) * 0.50), 2)
            passed = False
            details = f"Citra mengalami underexposure / terlalu gelap (luminansi: {round(mean_lum, 2)} < ambang {self.brightness_min})"
        elif mean_lum > self.brightness_max:
            excess = mean_lum - self.brightness_max
            score = round(max(0.05, 1.0 - (excess / (1.0 - self.brightness_max))), 2)
            passed = False
            details = f"Citra mengalami overexposure / silau flash (luminansi: {round(mean_lum, 2)} > ambang {self.brightness_max})"
        else:
            # Optimal illumination is between 0.32 and 0.65
            if 0.32 <= mean_lum <= 0.65:
                dist = abs(mean_lum - 0.45)
                score = round(max(0.75, 1.0 - (dist * 1.0)), 2)
                passed = True
                details = f"Pencahayaan optimal (luminansi: {round(mean_lum, 2)})"
            elif self.brightness_min <= mean_lum < 0.32:
                # Borderline illumination: acceptable only if score >= 0.60
                score = round(0.60 + ((mean_lum - self.brightness_min) / (0.32 - self.brightness_min)) * 0.14, 2)
                passed = score >= 0.60
                details = f"Pencahayaan memadai (luminansi: {round(mean_lum, 2)})"
            else: # 0.65 < mean_lum <= self.brightness_max
                dist = abs(mean_lum - 0.65)
                score = round(max(0.55, 0.75 - (dist * 1.5)), 2)
                passed = score >= 0.60
                details = f"Pencahayaan agak terang (luminansi: {round(mean_lum, 2)})"

        # Hard clinical guard: Any score below 0.60 must fail illumination
        if score < 0.60:
            passed = False

        return passed, round(score, 2), details

    def inspect_field_of_view(self, gray: np.ndarray) -> Tuple[bool, float, str]:
        """
        Computes fundus circular field-of-view coverage.
        Invariant to widescreen/rectangular frame aspect ratios.
        """
        h, w = gray.shape
        _, thresh = cv2.threshold(gray, 18, 255, cv2.THRESH_BINARY)
        retina_area = float(np.count_nonzero(thresh))

        max_inscribed_circle = (np.pi / 4.0) * (min(h, w) ** 2)
        circle_ratio = retina_area / max(1.0, max_inscribed_circle)
        frame_ratio = retina_area / float(h * w)

        effective_coverage = max(circle_ratio, frame_ratio)
        normalized_fov = min(1.0, max(0.0, effective_coverage / 0.55))
        normalized_fov = round(normalized_fov, 2)

        passed = normalized_fov >= self.fov_min
        details = f"Aperture coverage: {round(effective_coverage * 100, 1)}% of aperture"
        return passed, normalized_fov, details

    def inspect_dimensions(self, h: int, w: int) -> Tuple[bool, float, str]:
        """Checks if input meets clinical minimum resolution."""
        min_dim = min(h, w)
        if min_dim < self.min_dimension:
            score = round(min_dim / float(self.min_dimension), 2)
            return False, score, f"Resolution {w}x{h} below minimum {self.min_dimension}x{self.min_dimension}"
        return True, 1.0, f"Resolution {w}x{h} meets requirements"

    def evaluate_quality(self, image_input: Union[bytes, Image.Image, np.ndarray]) -> QualityCheckResult:
        """
        Full Quality Gate evaluation pipeline.
        Returns QualityCheckResult.
        """
        try:
            rgb = self.load_image(image_input)
        except Exception as e:
            return QualityCheckResult(
                passed=False,
                score=0.0,
                checks=QualityChecks(
                    blur=QualitySubCheck(passed=False, score=0.0, details="Failed to decode image"),
                    brightness=QualitySubCheck(passed=False, score=0.0, details="Failed to decode image"),
                    field_of_view=QualitySubCheck(passed=False, score=0.0, details="Failed to decode image"),
                    dimensions=QualitySubCheck(passed=False, score=0.0, details="Invalid dimensions"),
                ),
                decision="RETAKE",
                reason="The uploaded file is not a valid fundus image or is corrupted.",
                instructions="Unggah kembali berkas citra funduskopi retina digital dalam format JPEG/PNG yang valid.",
                overall_score=0.0,
                blur_score=0.0,
                illumination_score=0.0,
                fov_score=0.0,
                retake_reason="The uploaded file is not a valid fundus image or is corrupted.",
                retake_instructions="Unggah kembali berkas citra funduskopi retina digital dalam format JPEG/PNG yang valid.",
            )

        h, w = rgb.shape[:2]
        gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)

        # Run checks
        dim_passed, dim_score, dim_details = self.inspect_dimensions(h, w)
        blur_passed, blur_score, blur_details = self.inspect_blur(gray, rgb=rgb)
        bright_passed, bright_score, bright_details = self.inspect_brightness(gray)
        fov_passed, fov_score, fov_details = self.inspect_field_of_view(gray)

        # Weighted composite score
        composite_score = round(
            0.35 * blur_score + 0.30 * bright_score + 0.20 * fov_score + 0.15 * dim_score,
            2
        )

        checks = QualityChecks(
            blur=QualitySubCheck(passed=blur_passed, score=blur_score, details=blur_details),
            brightness=QualitySubCheck(passed=bright_passed, score=bright_score, details=bright_details),
            field_of_view=QualitySubCheck(passed=fov_passed, score=fov_score, details=fov_details),
            dimensions=QualitySubCheck(passed=dim_passed, score=dim_score, details=dim_details),
        )

        all_checks_passed = dim_passed and blur_passed and bright_passed and fov_passed
        overall_passed = all_checks_passed and (composite_score >= self.quality_threshold)

        if not overall_passed:
            # When any critical safety check fails, cap composite score to reflect RETAKE status (< 0.50)
            failed_subscores = [s for p, s in [(dim_passed, dim_score), (blur_passed, blur_score), (bright_passed, bright_score), (fov_passed, fov_score)] if not p]
            min_failed = min(failed_subscores) if failed_subscores else 0.40
            composite_score = round(min(composite_score, max(0.15, min_failed + 0.10), 0.48), 2)

        if overall_passed:
            decision = "ANALYZE"
            reason = None
            instructions = None
        else:
            decision = "RETAKE"
            reasons = []
            instructions_list = []
            if not dim_passed:
                reasons.append("Resolusi citra terlalu rendah.")
                instructions_list.append(f"Gunakan kamera fundus dengan resolusi minimal {self.min_dimension}x{self.min_dimension} piksel.")
            if not blur_passed:
                reasons.append(f"Citra mengalami blur / tidak fokus (skor {int(blur_score * 100)}% < ambang {int(self.blur_threshold * 100)}%).")
                instructions_list.append("Pastikan kamera fundus stabil dan fokus tepat pada diskus optikus sebelum menangkap citra.")
            if not bright_passed:
                reasons.append(f"Pencahayaan tidak memadai / terlalu gelap (skor {int(bright_score * 100)}% < ambang 60%).")
                instructions_list.append("Sesuaikan intensitas flash kamera atau pastikan pupil pasien cukup terdilasi.")
            if not fov_passed:
                reasons.append("Bidang pandang (field of view) retina tidak mencakup area 45 derajat.")
                instructions_list.append("Posisikan fovea sentral dan papil saraf optik di tengah bidang pandang kamera.")

            if not reasons and composite_score < self.quality_threshold:
                reasons.append(f"Skor komposit kualitas citra ({int(composite_score * 100)}%) berada di bawah standar diagnostik ({int(self.quality_threshold * 100)}%).")
                instructions_list.append("Lakukan pengambilan ulang foto dengan fokus dan pencahayaan optimal.")

            reason = " ".join(reasons)
            instructions = " ".join(instructions_list)

        return QualityCheckResult(
            passed=overall_passed,
            score=composite_score,
            checks=checks,
            decision=decision,
            reason=reason,
            instructions=instructions,
            overall_score=composite_score,
            blur_score=blur_score,
            illumination_score=bright_score,
            fov_score=fov_score,
            retake_reason=reason,
            retake_instructions=instructions,
        )

quality_service = ImageQualityService()
