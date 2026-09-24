import { NextResponse } from "next/server";
import { DomainError, NotFoundError, ConflictError, UnauthorizedError, ForbiddenError, ValidationError } from "@/domain/common/errors";

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
    details?: any;
  };
  meta?: {
    timestamp: string;
    version: string;
    total?: number;
    limit?: number;
    offset?: number;
  };
}

export class HttpResponse {
  public static success<T>(data: T, status = 200, meta?: Partial<ApiResponse["meta"]>): NextResponse {
    const responseBody: ApiResponse<T> = {
      success: true,
      data,
      meta: {
        timestamp: new Date().toISOString(),
        version: "v1",
        ...meta,
      },
    };
    return NextResponse.json(responseBody, { status });
  }

  public static created<T>(data: T, meta?: Partial<ApiResponse["meta"]>): NextResponse {
    return this.success(data, 201, meta);
  }

  public static error(message: string, code = "INTERNAL_ERROR", status = 500, details?: any): NextResponse {
    const responseBody: ApiResponse = {
      success: false,
      error: {
        code,
        message,
        details,
      },
      meta: {
        timestamp: new Date().toISOString(),
        version: "v1",
      },
    };
    return NextResponse.json(responseBody, { status });
  }

  public static handleException(err: unknown): NextResponse {
    console.error("[RETIVA_API_EXCEPTION]:", err);

    if (err instanceof NotFoundError) {
      return this.error(err.message, err.code, 404);
    }
    if (err instanceof ConflictError) {
      return this.error(err.message, err.code, 409);
    }
    if (err instanceof UnauthorizedError) {
      return this.error(err.message, err.code, 401);
    }
    if (err instanceof ForbiddenError) {
      return this.error(err.message, err.code, 403);
    }
    if (err instanceof ValidationError) {
      return this.error(err.message, err.code, 400, err.validationErrors);
    }
    if (err instanceof DomainError) {
      return this.error(err.message, err.code, 400);
    }
    if (err instanceof Error) {
      return this.error(err.message, "SERVER_ERROR", 500);
    }
    return this.error("An unexpected error occurred.", "UNKNOWN_ERROR", 500);
  }
}
