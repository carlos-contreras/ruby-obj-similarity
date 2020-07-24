
class ObjectSimilarity
  CAPTURE_WORDS_REGEX = /\"(.*?)\"/x

  def initialize
    @file_cache = Hash.new
  end

  def get_file_text(file_path)
    @file_cache[file_path] ||= begin
      file = File.open(file_path)
      text = file
        .read
        .gsub(" ", "")
        .gsub("\n", "")
        .gsub("\t", "")

      file.close
      text
    end
  end

  def get_json_object_words(json_txt)
    json_txt
      .scan(CAPTURE_WORDS_REGEX)
      .flatten
      .group_by { |i| i }
      .each_with_object({}) { |(key, arr), obj| obj[key] = arr.length }
  end

  def compare_files(file1_path, file2_path)
    file1_str = get_file_text(file1_path)
    file2_str = get_file_text(file2_path)

    shorter_str, longer_str = file1_str.length < file2_str.length ? [file1_str, file2_str] : [file2_str, file1_str]

    grouped_words_1 = get_json_object_words(file1_str)
    grouped_words_2 = get_json_object_words(file2_str)

    shorter_group_of_words, longer_group_of_words = grouped_words_1.keys.length < grouped_words_2.keys.length ? [grouped_words_1, grouped_words_2] : [grouped_words_2, grouped_words_1]

    temp_object = shorter_group_of_words.each_with_object({}) do |(word, count), obj|
      if longer_group_of_words.key?(word)
        diff = count - longer_group_of_words[word]
        obj[word] = diff
      else
        obj[word] = count
      end
    end

    words_diff = longer_group_of_words.merge(temp_object).filter { |word, count| count != 0 }.each_with_object({}) { |(word, count), obj| obj[word] = count > 0 ? count : count * -1}.reduce(0) { |sum, (word, count)| sum += word.length * count }

    remaining_chars_1 = grouped_words_1.keys.sort_by { |key| key.length}.reverse.reduce(file1_str) do |remaining_str, word|
      remaining_str.gsub(word, "")
    end

    remaining_chars_1 = remaining_chars_1.split("").group_by { |i| i }.each_with_object({}) { |(char, times), obj| obj[char] = times.length }

    remaining_chars_2 = grouped_words_2.keys.sort_by { |key| key.length}.reverse.reduce(file2_str) do |remaining_str, word|
      remaining_str.gsub(word, "")
    end

    remaining_chars_2 = remaining_chars_2.split("").group_by { |i| i }.each_with_object({}) { |(char, times), obj| obj[char] = times.length }

    shorter2, longer2 = remaining_chars_1.keys.length < remaining_chars_2.keys.length ? [remaining_chars_1, remaining_chars_2] : [remaining_chars_2, remaining_chars_1]

    temp_object2 = shorter2.each_with_object({}) do |(char, count), obj|
      if longer2.key?(char)
        diff = count - longer2[char]
        obj[char] = diff
      else
        obj[char] = count
      end
    end

    chars_diff = longer2.merge(temp_object2).filter { |char, count| count != 0 }.each_with_object({}) { |(char, count), obj| obj[char] = count > 0 ? count : count * -1}.reduce(0) { |sum, (char, count)| sum += char.length * count }

    total_raw_diff = (chars_diff + words_diff).to_f

    max_similarity = 1 - (total_raw_diff / longer_str.length.to_f)

    max_similarity
  end
end

file_paths = Dir.children("data").map { |file_name| "data/#{file_name}"}
service_object = ObjectSimilarity.new

file_paths.combination(2).to_a.each do |file_couple|
  puts "Comparing #{file_couple}"
  similarity = service_object.compare_files(*file_couple)
  puts "Similarity: #{similarity}"
end
