# === DATABASE ===

class ArangoDB < ArangoS
  def initialize(database: @@database)
    if database.is_a?(String)
      @database = database
    else
      raise "database should be a String, not a #{database.class}"
    end
  end

  attr_reader :database

  # === GET ===

  def self.info
    result = get("/_api/database/current", @@request)
    return_result result: result, key: "result"
    # @@verbose ? result : result["error"] ? result["errorMessage"] : result["result"]
  end

  # === POST ===

  def create(username: nil, passwd: nil, users: nil)
    body = {
      "name" => @database,
      "username" => username,
      "passwd" => passwd,
      "users" => users
    }
    body = body.delete_if{|k,v| v.nil?}.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_api/database", request)
    @@async == "store" ? result.headers["x-arango-async-id"] : @@verbose ? result.parsed_response : result.parsed_response["error"] ? result.parsed_response["errorMessage"] : self
  end

  # === DELETE ===

  def destroy
    result = self.class.delete("/_api/database/#{@database}", @@request)
    self.class.return_result(result: result, caseTrue: true)
  end

  # === LISTS ===

  def self.databases(user: nil)
    result = user.nil? ? get("/_api/database") : get("/_api/database/#{user}", @@request)
    @@async == "store" ? result.headers["x-arango-async-id"] : @@verbose ? result.parsed_response : result.parsed_response["error"] ? result.parsed_response["errorMessage"] : result.parsed_response["result"].map{|x| ArangoDB.new(database: x)}
  end

  def collections(excludeSystem: true)
    query = { "excludeSystem": excludeSystem }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/collection", request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          result["result"].map{|x| ArangoC.new(database: @database, collection: x["name"])}
        end
      end
    end
  end

  def graphs
    result = self.class.get("/_db/#{@database}/_api/gharial", @@request)
    if @@async == "store"
      result.headers["x-arango-async-id"]
    else
      result = result.parsed_response
      if @@verbose
        result
      else
        if result["error"]
          result["errorMessage"]
        else
          result["graphs"].map{|x| ArangoG.new(database: @database, graph: x["_key"], edgeDefinitions: x["edgeDefinitions"], orphanCollections: x["orphanCollections"])}
        end
      end
    end
  end

  def functions
    result = self.class.get("/_db/#{@database}/_api/aqlfunction", @@request)
    self.class.return_result result: result
  end

  # === QUERY ===

  def propertiesQuery
    result = self.class.get("/_db/#{@database}/_api/query/properties", @@request)
    self.class.return_result result: result
  end

  def currentQuery
    result = self.class.get("/_db/#{@database}/_api/query/current", @@request)
    self.class.return_result result: result
  end

  def slowQuery
    result = self.class.get("/_db/#{@database}/_api/query/slow", @@request)
    self.class.return_result result: result
  end

  def stopSlowQuery
    result = self.class.delete("/_db/#{@database}/_api/query/slow", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  def killQuery(id:)
    result = self.class.delete("/_db/#{@database}/_api/query/#{id}", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  def changePropertiesQuery(slowQueryThreshold: nil, enabled: nil, maxSlowQueries: nil, trackSlowQueries: nil, maxQueryStringLength: nil)
    body = {
      "slowQueryThreshold" => slowQueryThreshold,
      "enabled" => enabled,
      "maxSlowQueries" => maxSlowQueries,
      "trackSlowQueries" => trackSlowQueries,
      "maxQueryStringLength" => maxQueryStringLength
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/query/properties", request)
    self.class.return_result result: result
  end

# === CACHE ===

  def clearCache
    result = self.class.delete("/_db/#{@database}/_api/query-cache", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  def propertyCache
    result = self.class.get("/_db/#{@database}/_api/query-cache/properties", @@request)
    self.class.return_result result: result
  end

  def changePropertyCache(mode: nil, maxResults: nil)
    body = { "mode" => mode, "maxResults" => maxResults }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/query-cache/properties", request)
    self.class.return_result result: result
  end

  # === AQL FUNCTION ===

  def createFunction(code:, name:, isDeterministic: nil)
    body = {
      "code" => code,
      "name" => name,
      "isDeterministic" => isDeterministic
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.post("/_db/#{@database}/_api/aqlfunction", request)
    self.class.return_result result: result
  end

  def deleteFunction(name:)
    result = self.class.delete("/_db/#{@database}/_api/aqlfunction/#{name}", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  # === ASYNC ===

  def pendingAsync
    result = self.class.put("/_db/#{@database}/_api/job/pending", @@request)
    self.class.return_result result: result
  end

  def fetchAsync(id)
    result = self.class.put("/_db/#{@database}/_api/job/#{id}", @@request)
    self.class.return_result result: result
  end

  def retrieveAsync(id)
    result = self.class.get("/_db/#{@database}/_api/job/#{id}", @@request)
    self.class.return_result result: result
  end

  def cancelAsync(id)
    result = self.class.put("/_db/#{@database}/_api/job/#{id}/cancel", @@request)
    self.class.return_result result: result
  end

  def destroyAsync(type)
    result = self.class.delete("/_db/#{@database}/_api/job/#{type}", @@request)
    self.class.return_result result: result, caseTrue: true
  end

  def destroyAllAsync
    destroyAsync("all")
  end

  # === REPLICATION ===

  def inventory(includeSystem: false)
    query = { "includeSystem": includeSystem }
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/replication/inventory", request)
    self.class.return_result result: result
  end

  def clusterInventory(includeSystem: false)
    query = { "includeSystem": includeSystem }
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/replication/clusterInventory", request)
    self.class.return_result result: result
  end

  def logger
    result = self.class.get("/_db/#{@database}/_api/replication/logger-state")
    self.class.return_result result: result
  end

  def lastLogger(from: nil, to: nil, chunkSize: nil, includeSystem: false)
    query = {
      "from": from,
      "to": to,
      "chunkSize": chunkSize,
      "includeSystem": includeSystem
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :query => query })
    result = self.class.get("/_db/#{@database}/_api/replication/logger-follow", request)
    self.class.return_result result: result
  end

  def firstTick
    result = self.class.get("/_db/#{@database}/_api/replication/logger-first-tick")
    self.class.return_result result: result
  end

  def rangeTick
    result = self.class.get("/_db/#{@database}/_api/replication/logger-tick-ranges")
    self.class.return_result result: result
  end

  def sync(username:, password:, includeSystem:, endpoint:, initialSyncMaxWaitTime: nil, database: @database, restrictType: nil, incremental: nil, restrictCollections: nil)
    body = {
      "username" => username,
      "password" => password,
      "includeSystem" => includeSystem,
      "endpoint" => includeSystem,
      "initialSyncMaxWaitTime" => initialSyncMaxWaitTime,
      "database" => @database,
      "restrictType" => restrictType,
      "incremental" => incremental,
      "restrictCollections" =>  restrictCollections
    }.delete_if{|k,v| v.nil?}
    request = @@request.merge({ :body => body.to_json })
    result = self.class.put("/_db/#{@database}/_api/replication/sync", request)
    self.class.return_result result: result
  end

  # === USER ===

  def grant(user: @@user)
    body = { "grant" => "rw" }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_api/user/#{user}/database/#{@database}", new_DB)
    self.class.return_result result: result, caseTrue: true
  end

  def revoke(user: @@user)
    body = { "grant" => "none" }.to_json
    request = @@request.merge({ :body => body })
    result = self.class.post("/_api/user/#{user}/database/#{@database}", new_DB)
    self.class.return_result result: result, caseTrue: true
  end

  # === UTILITY ===

  # def return_result(result)
  #   if @@verbose
  #     result
  #   else
  #     if result["error"]
  #       result["errorMessage"]
  #     else
  #       result.delete("error")
  #       result.delete("code")
  #       result
  #     end
  #   end
  # end
end
