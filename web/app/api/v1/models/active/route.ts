import { NextRequest } from "next/server";
import { modelVersionRepository } from "@/lib/container";
import { HttpResponse } from "@/lib/http-response";
import { AuthGuard } from "@/infrastructure/security/auth.guard";

export async function GET(req: NextRequest) {
  try {
    AuthGuard.authenticate(req);
    const activeModel = await modelVersionRepository.getActiveModel();

    if (!activeModel) {
      return HttpResponse.success({
        modelName: "efficientnet-b3",
        version: "efficientnet-b3-v1.0.0",
        pipelineVersion: "dr-pipe-v1.2",
        weightsHash: "sha256:8f4e2c9a1d3b7e5f6a0c8b9d2e4f6a8b1c3d5e7f9a0b2c4d6e8f0a2b4c6d8e0f",
        thresholds: {
          qualityPassThreshold: 0.75,
          reliabilityHighThreshold: 0.85,
          reliabilityLowThreshold: 0.60,
        },
        classes: [
          "NO_DR",
          "MILD_DR",
          "MODERATE_DR",
          "SEVERE_DR",
          "PROLIFERATIVE_DR",
        ],
      });
    }

    return HttpResponse.success({
      ...activeModel.toJSON(),
      thresholds: {
        qualityPassThreshold: 0.75,
        reliabilityHighThreshold: 0.85,
        reliabilityLowThreshold: 0.60,
      },
      classes: [
        "NO_DR",
        "MILD_DR",
        "MODERATE_DR",
        "SEVERE_DR",
        "PROLIFERATIVE_DR",
      ],
    });
  } catch (error) {
    return HttpResponse.handleException(error);
  }
}
