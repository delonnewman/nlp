# frozen_string_literal: true

require 'yaml'

def read_model(file_name)
  YAML.load(IO.read(file_name))
end

model = read_model(ARGV[0])

first_token = model.keys.grep(/^[A-Z]/).sample
model[first_token]
