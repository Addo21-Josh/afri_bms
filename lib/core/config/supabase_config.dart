class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://cmuwfwzvwvjulydhnalq.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNtdXdmd3p2d3ZqdWx5ZGhuYWxxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTE1NjgxMjQsImV4cCI6MjEwNzE0NDEyNH0.0ZKjZFHkU9-avCEfFmfhjKCD7BlaSZHPZpdywXdfQ5U',
  );
}
