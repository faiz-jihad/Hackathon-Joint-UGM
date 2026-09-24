export class DomainError extends Error {
  constructor(message: string, public readonly code: string = "DOMAIN_ERROR") {
    super(message);
    this.name = this.constructor.name;
  }
}

export class NotFoundError extends DomainError {
  constructor(entityName: string, identifier?: string | number) {
    super(
      identifier ? `${entityName} with ID/Identifier ${identifier} was not found.` : `${entityName} was not found.`,
      "NOT_FOUND"
    );
  }
}

export class ConflictError extends DomainError {
  constructor(message: string) {
    super(message, "CONFLICT");
  }
}

export class ValidationError extends DomainError {
  constructor(message: string, public readonly validationErrors?: Record<string, string[]>) {
    super(message, "VALIDATION_ERROR");
  }
}

export class UnauthorizedError extends DomainError {
  constructor(message: string = "Authentication required or credentials invalid.") {
    super(message, "UNAUTHORIZED");
  }
}

export class ForbiddenError extends DomainError {
  constructor(message: string = "Access denied for this resource.") {
    super(message, "FORBIDDEN");
  }
}
