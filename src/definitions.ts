export interface ListenPlugin {
  echo(options: { value: string }): Promise<{ value: string }>;
}
