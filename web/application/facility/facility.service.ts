import { FacilityRepository, FacilitySearchParams } from "@/domain/facility/facility.repository";
import { Facility, BPJSStatus } from "@/domain/facility/facility.entity";
import { NotFoundError } from "@/domain/common/errors";

export interface MatchFacilityDTO {
  latitude: number;
  longitude: number;
  maxDistanceKm?: number;
  requiredService?: string; // e.g. "RETINA_SPECIALIST", "LASER_PHOTOCOAGULATION", "VITRECTOMY"
  requireBpjs?: boolean;
}

export interface MatchedFacilityResult {
  facility: Facility;
  distanceKm: number;
  bpjsAvailable: boolean;
  servicesAvailable: string[];
}

export class FacilityService {
  constructor(private readonly facilityRepository: FacilityRepository) {}

  async searchFacilities(params: FacilitySearchParams): Promise<{ facilities: Facility[]; total: number }> {
    return this.facilityRepository.search(params);
  }

  async getFacilityById(id: string): Promise<Facility> {
    const facility = await this.facilityRepository.findById(id);
    if (!facility) {
      throw new NotFoundError("Facility", id);
    }
    return facility;
  }

  /**
   * Rule-based Facility Matching Engine.
   * STRICT ARCHITECTURAL RULE:
   * AI does not pick healthcare facilities directly.
   * Matching is purely deterministic application logic based on coordinates, services, and BPJS availability.
   */
  async matchFacilities(dto: MatchFacilityDTO): Promise<MatchedFacilityResult[]> {
    const allFacilities = await this.facilityRepository.listAll();
    const maxDistance = dto.maxDistanceKm || 50; // 50km default radius

    const matched: MatchedFacilityResult[] = [];

    for (const f of allFacilities) {
      // 1. Service filter
      if (dto.requiredService && !f.hasService(dto.requiredService)) {
        continue;
      }

      // 2. BPJS requirement filter
      if (dto.requireBpjs && f.bpjsStatus !== "ACCEPTED") {
        continue;
      }

      // 3. Geodesic distance calculation via Haversine formula
      const distanceKm = f.calculateDistanceKm(dto.latitude, dto.longitude);
      if (distanceKm <= maxDistance) {
        matched.push({
          facility: f,
          distanceKm,
          bpjsAvailable: f.bpjsStatus === "ACCEPTED",
          servicesAvailable: f.services.map((s) => s.serviceName),
        });
      }
    }

    // Rank: verified facilities first, then by shortest distance
    matched.sort((a, b) => {
      if (a.facility.isVerified && !b.facility.isVerified) return -1;
      if (!a.facility.isVerified && b.facility.isVerified) return 1;
      return a.distanceKm - b.distanceKm;
    });

    return matched.slice(0, 10);
  }
}
