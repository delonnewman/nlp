# frozen_string_literal: true

require 'yaml'

def read_model(file_name)
  YAML.load(IO.read(file_name))
end

def trigrams
  @trigrams ||= read_model('moby-dick-trigrams.yaml')
end

def bigrams
  @bigrams ||= read_model('moby-dick-bigrams.yaml')
end

def next_token(index)
  target = rand
  index.each do |token, weight|
    return token if target <= weight

    target -= weight
  end
end

def next_phrase(seed)
  one = next_token(bigrams[seed])
  two = next_token(trigrams.dig(seed, one))
  three = next_token(trigrams.dig(one, two))

  [one, two, three]
end

def sentence(first = nil, periods = 0)
  seed = first || bigrams.keys.grep(/^[A-Z]/).sample
  phrase = next_phrase(seed)
  return phrase if periods == 3

  periods += 1 if phrase.include?('.')

  if periods.zero?
    [seed, phrase, sentence(phrase.last, periods)].flatten
  else
    [phrase, sentence(phrase.last, periods)].flatten
  end
end

puts sentence(ARGV[0]).join(' ') if $PROGRAM_NAME == __FILE__
