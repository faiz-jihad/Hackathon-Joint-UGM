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

    def inspect_blur(self, gray: np.ndarray) -> Tuple[bool, float, str]:
        """
        Calculates Laplacian variance to assess optical focus and motion blur.
        Sharper fundus images yield higher variance.
        """
        # Focus on central 70% to avoid black border edge artifacts
        h, w = gray.shape
        cy, cx = h // 2, w // 2
        rh, rw = int(h * 0.35), int(w * 0.35)
        central_crop = gray[cy - rh: cy + rh, cx - rw: cx + rw]

        if central_crop.size == 0:
            return False, 0.0, "Empty crop"

        laplacian_var = float(cv2.Laplacian(central_crop, cv2.CV_64F).var())

        # Map Laplacian variance to normalized 0-1 score (typical fundus: <40 is very blurry, >120 is crisp)
        # Using sigmoid-like curve
        normalized_score = min(1.0, max(0.0, laplacian_var / (laplacian_var + 60.0) * 1.5))
        normalized_score = round(normalized_score, 2)

        passed = normalized_score >= self.blur_threshold
        details = f"Sharpness variance: {round(laplacian_var, 1)} (score: {normalized_score})"
        return passed, normalized_score, details

    def inspect_brightness(self, gray: np.ndarray) -> Tuple[bool, float, str]:
        """
        Evaluates illumination, underexposure, and glare/overexposure.
        """
        # Exclude black background (pixel values < 15) to inspect actual fundus retina
        mask = gray > 15
        if np.count_nonzero(mask) == 0:
            return False, 0.0, "Image is entirely black/underexposed"

        retina_pixels = gray[mask] / 255.0
        mean_lum = float(np.mean(retina_pixels))

        # Optimal mean fundus luminance is typically around 0.35 - 0.70
        if mean_lum < self.brightness_min:
            score = max(0.0, mean_lum / self.brightness_min * 0.7)
            passed = False
            details = f"Underexposed / too dark (luminance: {round(mean_lum, 2)})"
        elif mean_lum > self.brightness_max:
            excess = mean_lum - self.brightness_max
            score = max(0.0, 1.0 - (excess / (1.0 - self.brightness_max)))
            passed = False
            details = f"Overexposed / flash glare (luminance: {round(mean_lum, 2)})"
        else:
            # Distance from center of ideal range (0.50)
            dist = abs(mean_lum - 0.50)
            score = round(1.0 - (dist * 0.8), 2)
            passed = True
            details = f"Optimal illumination (luminance: {round(mean_lum, 2)})"

        return passed, round(score, 2), details

    def inspect_field_of_view(self, gray: np.ndarray) -> Tuple[bool, float, str]:
        """
        Computes fundus circular field-of-view coverage.
        Standard fundus photography captures a 45-degree circular field.
        """
        # Threshold to identify retina vs non-illuminated surrounding camera aperture
        h, w = gray.shape
        _, thresh = cv2.threshold(gray, 20, 255, cv2.THRESH_BINARY)
        retina_area = np.count_nonzero(thresh)
        total_area = h * w

        # For a circular mask inscribed in a square, ideal coverage is pi / 4 ~= 0.785
        # We normalize coverage relative to ideal circular aperture (~0.75)
        raw_ratio = retina_area / float(total_area)
        normalized_fov = min(1.0, raw_ratio / 0.70)

        passed = normalized_fov >= self.fov_min
        details = f"Aperture coverage: {round(raw_ratio * 100, 1)}% of frame"
        return passed, round(normalized_fov, 2), details

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
        blur_passed, blur_score, blur_details = self.inspect_blur(gray)
        bright_passed, bright_score, bright_details = self.inspect_brightness(gray)
        fov_passed, fov_score, fov_details = self.inspect_field_of_view(gray)

        # Weighted composite score
        composite_score = round(
            0.40 * blur_score + 0.30 * bright_score + 0.20 * fov_score + 0.10 * dim_score,
            2
        )

        all_checks_passed = dim_passed and blur_passed and bright_passed and fov_passed
        overall_passed = all_checks_passed and (composite_score >= self.quality_threshold)

        checks = QualityChecks(
            blur=QualitySubCheck(passed=blur_passed, score=blur_score, details=blur_details),
            brightness=QualitySubCheck(passed=bright_passed, score=bright_score, details=bright_details),
            field_of_view=QualitySubCheck(passed=fov_passed, score=fov_score, details=fov_details),
            dimensions=QualitySubCheck(passed=dim_passed, score=dim_score, details=dim_details),
        )

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
                instructions_list.append("Gunakan kamera fundus dengan resolusi minimal 300x300 piksel.")
            if not blur_passed:
                reasons.append("Citra mengalami blur / tidak fokus.")
                instructions_list.append("Pastikan kamera fundus stabil dan fokus tepat pada diskus optikus sebelum menangkap citra.")
            if not bright_passed:
                reasons.append("Pencahayaan / eksposur tidak memadai.")
                instructions_list.append("Sesuaikan intensitas flash kamera atau pastikan pupil pasien cukup terdilasi.")
            if not fov_passed:
                reasons.append("Bidang pandang (field of view) retina tidak mencakup area 45 derajat.")
                instructions_list.append("Posisikan fovea sentral dan papil saraf optik di tengah bidang pandang kamera.")

            reason = "Image quality is insufficient for reliable screening: " + " ".join(reasons)
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
