# === AQL ===

class ArangoAQL < ArangoServer
  def initialize(query: nil, batchSize: nil, ttl: nil, cache: nil, options: nil, bindVars: nil, database: @@database)  # TESTED
    if query.is_a?(String)
      @query = query
    elsif query.is_a?(ArangoAQL)
      @query = query.query
    else
      raise "query should be String or ArangoAQL instance, not a #{query.class}"
    end
    @database = database
    @batchSize = batchSize
    @ttl = ttl
    @cache = cache
    @options = options
    @bindVars = bindVars

    @count = 0
    @hasMore = false
    @id = ""
    @result = []
  end

  attr_accessor :query, :batchSize, :ttl, :cache, :options, :bindVars
  attr_reader :count, :database, :count, :hasMore, :id, :result
  alias size batchSize
  alias size= batchSize=

# === EXECUTE QUERY ===

  def execute(count: true) # TESTED
    body = {
      "query" => @query,
      "count" => count,
      "batchSize" => @batchSize,
      "ttl" => @count,
      "cache" => @cache,
      "options" => @options,
      "bindVars" => @bindVars
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/cursor", request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if result["error"]
        return @@verbose ? result : result["errorMessage"]
      else
        @count = result["count"]
        @hasMore = result["hasMore"]
        @id = result["id"]
        if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
          @result = result["result"]
        else
          @result = result["result"].map{|x| ArangoDocument.new(
            key: x["_key"],
            collection: x["_id"].split("/")[0],
            database: @database,
            body: x
          )}
        end
        return @@verbose ? result : self
      end
    end
  end

  def next  # TESTED
    unless @hasMore
      print "No other results"
    else
      result = self.class.put("/_db/#{@database}/_api/cursor/#{@id}", @@request)
      if @@async == "store"
        result.headers["x-arango-async-id"]
      else
        result = result.parsed_response
        if result["error"]
          return @@verbose ? result : result["errorMessage"]
        else
          @count = result["count"]
          @hasMore = result["hasMore"]
          @id = result["id"]
          if(result["result"][0].nil? || !result["result"][0].is_a?(Hash) || !result["result"][0].key?("_key"))
            @result = result["result"]
          else
            @result = result["result"].map{|x| ArangoDocument.new(
              key: x["_key"],
              collection: x["_id"].split("/")[0],
              database: @database,
              body: x
            )}
          end
          return @@verbose ? result : self
        end
      end
    end
  end

  # === PROPERTY QUERY ===

  def explain  # TESTED
    body = {
      "query" => @query,
      "options" => @options,
      "bindVars" => @bindVars
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/explain", request)
    return_result result: result
  end

  def parse # TESTED
    body = { "query" => @query }
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/query", request)
    return_result result: result
  end

  def properties # TESTED
    result = self.class.get("/_db/#{@database}/_api/query/properties", @@request)
    return_result result: result
  end

  def current # TESTED
    result = self.class.get("/_db/#{@database}/_api/query/current", @@request)
    return_result result: result
  end

  def slow # TESTED
    result = self.class.get("/_db/#{@database}/_api/query/slow", @@request)
    return_result result: result
  end

# === DELETE ===

  def stopSlow # TESTED
    result = self.class.delete("/_db/#{@database}/_api/query/slow", @@request)
    return_result result: result, caseTrue: true
  end

  def kill(id: @id) # TESTED
    result = self.class.delete("/_db/#{@database}/_api/query/#{id}", @@request)
    return_result result: result, caseTrue: true
  end

  def changeProperties(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil) # TESTED
    body = {
      "slowQueryThreshold" => slowQueryThreshold,
      "enabled" => enabled,
      "maxSlowQueries" => maxSlowQueries,
      "trackSlowQueries" => trackSlowQueries,
      "maxQueryStringLength" => maxQueryStringLength
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/query/properties", request)
    return_result result: result
  end

# === UTILITY ===

  def return_result(result:, caseTrue: false)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result.is_a?(Hash) && result["error"]
          result["errorMessage"]
        else
          return true if caseTrue
          result.delete("error")
          result.delete("code")
          result
        end
      end
    end
  end
end
