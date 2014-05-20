module CacheHelper
  def generate_cache_key(args = {})
    method = caller[0][/`.*'/][1..-2]
    sprintf("%s-%s\(%s\)", self.class.name, method, args.map{|k, v| "#{k}:#{v}"}.join("-"))
  end
end
