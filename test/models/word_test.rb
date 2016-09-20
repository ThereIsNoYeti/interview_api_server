require File.expand_path('../../../config/environment', __FILE__)

require 'active_support'
require 'rails/test_help'

require 'test_helper'

class WordTest < ActiveSupport::TestCase
  test 'Word Test #01: Initializing dictionary from file' do
    _dictionary_file =  Rails.root.join('db', 'seed_data', 'short_dictionary.txt')
    Word.import_dictionary(_dictionary_file, purge: true)

    assert_equal(_dictionary_file.readlines.length, Word.count, 'Dictionary was not initialized')
  end

  test 'Word Test #02: Initializing dictionary from bad file' do
    _dictionary_file = Rails.root.join('lib', 'modules', 'dictionary_hash', 'bad_dictionary_file.txt')
    assert_raises(ArgumentError) { Word.import_dictionary(_dictionary_file) }
  end

  test 'Word Test #03: Adding a word' do
    _temp = Word.create(word: 'lua')

    assert(_temp.persisted?, 'Word was unable to be persisted!')
    assert(Word.where(word:'lua').exists?, 'Word was not found in the database!')
  end

  test 'Word Test #04: Adding a words' do
    Word.import_words(%w(ruby yrub byru ubyr))

    assert_equal(4, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')
  end

  test 'Word Test #05: Adding a word that already exists!' do
    _temp = Word.create(word: 'lua')

    assert(_temp.persisted?, 'Word was unable to be persisted!')
    assert(Word.where(word:'lua').exists?, 'Word was not found in the database!')

    _temp = Word.create(word: 'lua')

    assert_not(_temp.persisted?,         'Word was inappropriately persisted!')
    assert_not(_temp.errors.size.blank?, 'No error messages were added to the word to indicate failure!')
  end

  test 'Word Test #06: Removing a word' do
    _temp = Word.create(word: 'lua')

    assert(_temp.persisted?, 'Word was unable to be persisted!')
    assert(Word.where(word:'lua').exists?, 'Word was not found in the database!')

    Word.where(word: 'lua').destroy_all

    assert_not(Word.where(word:'lua').exists?, 'Word was incorrectly found in the database!')
  end

  test 'Word Test #07: Removing a word that doesn\'t exist' do
    _temp = Word.create(word: 'lua')

    assert(_temp.persisted?, 'Word was unable to be persisted!')
    assert(Word.where(word:'lua').exists?, 'Word was not found in the database!')

    _word_count = Word.count

    Word.where(word: 'nonsense').destroy_all

    assert_equal(_word_count, Word.count, 'A word was incorrectly removed, the count is off!')
  end

  test 'Word Test #08: Removing some words' do
    Word.import_words(%w(ruby yrub byru ubyr))

    assert_equal(4, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')

    Word.where(word: %w(ruby yrub)).destroy_all

    assert_equal(2, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')
  end

  test 'Word Test #08: Removing anagram words' do
    Word.import_words(%w(ruby yrub byru ubyr))

    assert_equal(4, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')

    Word.anagram_relation_for('ruby').destroy_all

    assert_equal(0, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Word failed to fetch correctly!')
  end

  test 'Word Test #09: Removing all words' do
    _temp = Word.create(word: 'lua')

    assert(_temp.persisted?, 'Word was unable to be persisted!')
    assert(Word.where(word:'lua').exists?, 'Word was not found in the database!')

    Word.destroy_all

    assert_equal(0, Word.count, 'Dictionary size is incorrect!')
    assert_not(Word.where(word:'lua').exists?, 'Word was found in the database!')
  end

  test 'Word Test #10: Fetch with multiple anagrams' do
    Word.import_words(%w(ruby yrub byru ubyr))

    assert_equal(4, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')

    assert_equal(4, Word.anagram_relation_for('ruby').size, 'Word failed to fetch correctly, too many or too few results!')
  end

  test 'Word Test #10.5: Fetch anagrams with self excluded' do
    Word.import_words(%w(ruby yrub byru ubyr))

    assert_equal(4, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')

    assert_equal(3, Word.anagram_relation_for('ruby', exclude_self: true).size, 'Word failed to fetch correctly, too many or too few results!')
  end

  test 'Word Test #11: Fetch with multiple anagrams with limit' do
    Word.import_words(%w(ruby yrub byru ubyr))

    assert_equal(4, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')
    assert_equal(2, Word.anagram_relation_for('ruby', limit: 2).size, 'Word failed to fetch correctly, too many or too few results!')
  end

  test 'Word Test #12: Fetch with multiple anagrams with over-limit' do
    Word.import_words(%w(ruby yrub byru ubyr))

    assert_equal(4, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')
    assert_equal(4, Word.anagram_relation_for('ruby', limit: 100).size, 'Word failed to fetch correctly, too many or too few results!')
  end

  test 'Word Test #13: Fetch with multiple anagrams with under-limit' do
    Word.import_words(%w(ruby yrub byru ubyr))

    assert_equal(4, Word.where(word: %w(ruby yrub byru ubyr)).count, 'Words were not found in the database!')
    assert_equal(4, Word.anagram_relation_for('ruby', limit: -1).size, 'Word failed to fetch correctly, too many or too few results!')
  end

  test 'Word Test #14: Meta-Data' do
    Word.import_words(%w(c ruby yrub byru ubyr), purge: true)

    _meta = Word.meta_data

    assert_equal(5, _meta[:word_count],            'Dictionary word count is incorrect!')
    assert_equal(1, _meta[:minimum_word_length],   'Dictionary minimum word length is incorrect!')
    assert_equal(4, _meta[:maximum_word_length],   'Dictionary maximum word length incorrect!')
    assert_equal(4, _meta[:median_word_length],    'Dictionary median word length is incorrect!')
    assert_equal(3.4, _meta[:average_word_length], 'Dictionary average word legnth is incorrect!')

  end

  test 'Word Test #15: Ignore proper nouns' do
    Word.import_words(%w(Ruby yrub byru ubyr), purge: true)

    assert_equal(4, Word.count,      'Dictionary size is incorrect!')
    assert_equal(3, Word.anagram_relation_for('ruby', exclude_proper_nouns: true).size, 'Word failed to fetch correctly, too many or too few results!')
  end

  test 'Word Test #16: Most anagrams' do
    Word.import_words( %w(ruby yrub byru ubyr swift tswif ftswi iftsw wifts), purge: true)

    assert(Word.most_anagrams.include?('swift'),  'Dictionary failed to detect words with most anagrams!')
  end

  test 'Word Test #17: Exact number of anagrams anagrams' do
    Word.import_words( %w(ruby yrub byru ubyr swift tswif ftswi iftsw wifts), purge: true)

    _anagrams_of_group_size = Word.anagram_groups_of_size(4).keys
    assert(_anagrams_of_group_size.include?(Word.string_to_anagram('ruby')),  'Dictionary failed to detect words with designated number of anagrams!')
  end
end
