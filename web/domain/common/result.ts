export class Result<T, E = Error> {
  public isSuccess: boolean;
  public isFailure: boolean;
  private readonly _error?: E;
  private readonly _value?: T;

  private constructor(isSuccess: boolean, error?: E, value?: T) {
    this.isSuccess = isSuccess;
    this.isFailure = !isSuccess;
    this._error = error;
    this._value = value;
  }

  public getValue(): T {
    if (!this.isSuccess) {
      throw new Error("Cannot get the value of an error result. Use 'error' instead.");
    }
    return this._value as T;
  }

  public getError(): E {
    if (this.isSuccess) {
      throw new Error("Cannot get the error of a success result. Use 'getValue' instead.");
    }
    return this._error as E;
  }

  public static ok<U>(value?: U): Result<U> {
    return new Result<U>(true, undefined, value);
  }

  public static fail<U, F = Error>(error: F): Result<U, F> {
    return new Result<U, F>(false, error);
  }
}
