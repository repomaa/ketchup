require "spec"
require "../../../src/core_ext/json/pull_parser"

describe JSON::PullParser do
  describe "skip with io" do
    it "skips a primitive json value" do
      parser = JSON::PullParser.new(%<{"foo": "bar", "baz": "foobar"}>)
      parser.read_object do |key|
        case key
        when "foo" then parser.skip(String::Builder.new)
        when "baz" then parser.read_string.should eq("foobar")
        else raise "Unexpected key #{key}"
        end
      end
    end

    it "skips a json object" do
      parser = JSON::PullParser.new(%<{"foo": {"bar": "baz", "foobar": "foo"}, "baz": "foobar"}>)
      parser.read_object do |key|
        case key
        when "foo" then parser.skip(String::Builder.new)
        when "baz" then parser.read_string.should eq("foobar")
        else raise "Unexpected key #{key}"
        end
      end
    end

    it "skips a json array" do
      parser = JSON::PullParser.new(%<{"foo": ["bar", "baz", {"foobar": "foo"}], "baz": "foobar"}>)
      parser.read_object do |key|
        case key
        when "foo" then parser.skip(String::Builder.new)
        when "baz" then parser.read_string.should eq("foobar")
        else raise "Unexpected key #{key}"
        end
      end
    end

    it "writes the skipped json to the given io" do
      io = String::Builder.new
      parser = JSON::PullParser.new(%<{"foo": ["bar", "baz", {"foobar": "foo"}], "baz": "foobar"}>)
      parser.read_object do |key|
        parser.skip(io) if key == "foo"
      end

      io.to_s.should eq(%<["bar","baz",{"foobar":"foo"}]>)
    end
  end
end
