class Word < ApplicationRecord
#== Class Header =======================================================================================================

#-- Included Modules ---------------------------------------------------------------------------------------------------

#-- Local Constants ----------------------------------------------------------------------------------------------------
  VALID_WORD_REGEXP = /\A[A-Za-z-]+\z/

#-- Plug-in Behaviors --------------------------------------------------------------------------------------------------

#-- Associations -------------------------------------------------------------------------------------------------------

#-- Callbacks ----------------------------------------------------------------------------------------------------------

#-- Validations --------------------------------------------------------------------------------------------------------
  validates :word,        presence: true, uniqueness: { case_sensitive: true }, format: { with: VALID_WORD_REGEXP, message: 'Words must be between 1 and 32 alpha-grammatical characters.' }
  validates :anagram_key, presence: true,                                       format: { with: VALID_WORD_REGEXP, message: 'Words must be between 1 and 32 alpha-grammatical characters.' }

  validate :matching_anagram_key?

#-- Accessors ----------------------------------------------------------------------------------------------------------

#== Singleton Methods ==================================================================================================
  public
  def self.string_to_anagram(word)
    word.to_s.downcase.chars.sort.join
  end

  def self.import_dictionary(load_file, purge: false)
    if load_file.present?
      begin
        self.destroy_all if purge
        File.readlines(load_file.to_s).each {|line| self.create(word: line.rstrip)}
      rescue Errno::ENOENT
        raise ArgumentError.new('Invalid dictionary file')
      end
    end
  end

  def self.import_words(words, purge: false)
    return false unless words.respond_to?(:each)

    self.destroy_all if purge

    _words = []
    words.each {|word| _words << Word.create(word: word)}
    _words
  end

  def self.anagram_relation_for(word, exclude_self: false, exclude_proper_nouns: false, limit: nil)
    _relation = self.where(anagram_key: self.string_to_anagram(word))
    _relation = _relation.limit(limit.to_i) if limit.present?
    _relation = _relation.where.not(word: word) if exclude_self
    _relation = _relation.where(('a'..'z').map {|letter|"word glob '#{letter}*'"}.join(' OR ')) if exclude_proper_nouns
    _relation
  end

  def self.meta_data
    {
        word_count:          self.count,
        minimum_word_length: self.minimum('LENGTH(word)'),
        maximum_word_length: self.maximum('LENGTH(word)'),
        median_word_length:  self.order('LENGTH(word) asc')[self.count/2].length,
        average_word_length: self.average('LENGTH(word)')
    }
  end

  def self.most_anagrams
    #Trash, but its late, I have a pluck all gem I made that makes this better
    _biggest_anagram_group = self.group(:anagram_key).limit(1).order('count_id desc').count(:id)
    self.where(anagram_key: _biggest_anagram_group.keys.first).pluck(:word)
  end

  def self.anagram_groups_of_size(minimum_size = 0)
    self.group(:anagram_key).having('count_id >= ?', minimum_size.to_i).count(:id)
  end

#== Public Methods =====================================================================================================
  public
  def word=(param)
    self.write_attribute(:word, param)
    self.write_attribute(:anagram_key, Word.string_to_anagram(param))
  end

  def length
    word.length
  end

#== Protected Methods ==================================================================================================
  protected
  def anagram_key=(param)
    self.write_attribute(:anagram_key, param)
  end

  def created_at=(param)
    self.write_attribute(:created_at, param)
  end

  def updated_at=(param)
    self.write_attribute(:updated_at, param)
  end

#== Private Methods ====================================================================================================
  private

  def matching_anagram_key?
    unless word.present? and self.word.downcase.chars.sort.join == self.anagram_key
      self.errors[:key_mismatch] << "Anagram key '#{anagram_key}' does not pair with word '#{word}'"
    end
  end

end
