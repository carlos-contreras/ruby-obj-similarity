# JSON Object Similarity Score

Write a program using JavaScript (Node) that will compare two json objects and give a score between 0 and 1 as to how similar they are, a score of 1 meaning the objects are identical. There are sample JSON files in the data directory for testing.

**Solution**

- The approach was to match words and remaining chars after removing all words form the JSON object, this implies the assumption of working with already validated JSON objects that overall share similar structure

```ruby
ruby main.rb
```