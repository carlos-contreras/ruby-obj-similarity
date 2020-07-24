
class ObjectSimilarity
  CAPTURE_WORDS_REGEX = /\"(.*?)\"/x

  def initialize
    @file_cache = Hash.new
  end

  def compare_files(file1_path, file2_path)
    file1_content = get_file_text(file1_path)
    file2_content = get_file_text(file2_path)

    grouped_words_1 = get_json_object_words(file1_content)
    grouped_words_2 = get_json_object_words(file2_content)

    words_diff = count_diff_of(grouped_words_1, grouped_words_2)

    remaining_chars_1 = get_remaining_chars_grouped(file1_content, grouped_words_1)
    remaining_chars_2 = get_remaining_chars_grouped(file2_content, grouped_words_2)

    chars_diff = count_diff_of(remaining_chars_1, remaining_chars_2)

    longer_str = file1_content.length > file2_content.length ? file1_content : file2_content
    1 - ((chars_diff + words_diff).to_f / longer_str.length.to_f)
  end

  private

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

  def count_diff_of(struct_1, struct_2)
    shorter, longer = struct_1.keys.length < struct_2.keys.length ? [struct_1, struct_2] : [struct_2, struct_1]

    temp_object = shorter.each_with_object({}) do |(key, count), obj|
      if longer.key?(key)
        diff = count - longer[key]
        obj[key] = diff
      else
        obj[key] = count
      end
    end

    longer
      .merge(temp_object)
      .filter { |word, count| count != 0 }
      .each_with_object({}) { |(word, count), obj| obj[word] = count > 0 ? count : count * -1}
      .reduce(0) { |sum, (word, count)| sum += word.length * count }
  end

  def get_remaining_chars_grouped(text, words_struct)
    words_struct
      .keys
      .sort_by { |key| key.length}
      .reverse
      .reduce(text) { |remaining_str, word| remaining_str.gsub(word, "") }
      .split("")
      .group_by { |i| i }
      .each_with_object({}) { |(char, times), obj| obj[char] = times.length }
  end
end

service_object = ObjectSimilarity.new

file_paths = Dir.children("data").map { |file_name| "data/#{file_name}"}

file_paths.combination(2).to_a.each do |file_couple|
  puts "Comparing #{file_couple}"
  similarity = service_object.compare_files(*file_couple)
  puts "Similarity: #{similarity}\n--"
end
