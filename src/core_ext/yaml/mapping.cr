module YAML
  macro mapping(properties, strict = false)
    {% for key, value in properties %}
      {% properties[key] = {type: value} unless value.is_a?(HashLiteral) %}
    {% end %}

    {% for key, value in properties %}
      def {{key.id}}=(_{{key.id}} : {{value[:type]}} {{ (value[:nilable] ? "?" : "").id }})
        @{{key.id}} = _{{key.id}}
      end

      def {{key.id}}
        @{{key.id}}
      end
    {% end %}

    def initialize(%pull : YAML::PullParser)
      {% for key, value in properties %}
        %var{key.id} =
          {% if value[:default] %}
            {{value[:default]}} as {{value[:type]}}
          {% else %}
            nil
          {% end %}
      {% end %}

      %pull.read_mapping_start
      while %pull.kind != YAML::EventKind::MAPPING_END
        key = %pull.read_scalar.not_nil!
        case key
        {% for key, value in properties %}
          when {{value[:key] || key.id.stringify}}
            %var{key.id} =
          {% if value[:nilable] == true || value[:default] %} %pull.read_null_or { {% end %}

            {% if value[:converter] %}
              {{value[:converter]}}.from_yaml(%pull)
            {% else %}
              {{value[:type]}}.new(%pull)
            {% end %}

            {% if value[:nilable] == true || value[:default] %} } {% end %}
        {% end %}
        else
          {% if strict %}
            raise YAML::ParseException.new("unknown yaml attribute: #{key}", 0, 0)
          {% else %}
            %pull.skip
          {% end %}
        end
      end
      %pull.read_next

      {% for key, value in properties %}
        {% unless value[:nilable] %}
          if %var{key.id}.is_a?(Nil)
            raise YAML::ParseException.new("missing yaml attribute: {{(value[:key] || key).id}}", 0, 0)
          end
        {% end %}
      {% end %}

      {% for key, value in properties %}
        @{{key.id}} = %var{key.id}
      {% end %}
    end
  end
end
