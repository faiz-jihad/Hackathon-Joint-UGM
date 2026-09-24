export abstract class BaseEntity<T> {
  protected readonly props: T;

  constructor(props: T) {
    this.props = props;
  }

  public abstract toJSON(): Record<string, any>;
}
