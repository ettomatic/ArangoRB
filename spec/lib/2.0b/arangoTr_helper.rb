require_relative './../../spec_helper'

describe Arango::Transaction do
  context "#new and use" do
    it "create new instance" do
      myArangoTransaction = @myDatabase.transaction action: "function(){ var db = require('@arangodb').db; db.MyCollection.save({}); return db.MyCollection.count(); }", write: @myCollection
      expect(myArangoTransaction.write[0].name).to eq "MyCollection"
    end

    it "execute" do
      myArangoTransaction = @myDatabase.transaction action: "function(){ var db = require('@arangodb').db; db.MyCollection.save({}); return db.MyCollection.count(); }", write: @myCollection
      expect(myArangoTransaction.execute).to be >= 1
    end
  end
end
