local Kache = require(script.Parent.prep)

return function()
    describe("Basic functionality", function()
        it("should store data", function()
            local instance = Kache.new()

            instance:Set("key", "value")
            expect(instance:Get("key")).to.equal("value")
        end)

        it("should use a default value if key does not exist", function()
            local instance = Kache.new()

            expect(instance:Get("key", "default")).to.equal("default")
        end)

        it("should allow functional default values", function()
            local instance = Kache.new()

            expect(instance:Get("key", function() return "default" end)).to.equal("default")
        end)

        it("should persist a default value if key does not exist and option is provided", function()
            local instance = Kache.new()

            expect(instance:Get("key", "default", true)).to.equal("default")
            expect(instance:Get("key")).to.equal("default")
        end)

        it("should support table-like behaviour", function()
            local instance = Kache.new()

            instance.key = "value"
            expect(instance.key).to.equal("value")
        end)
    end)

    describe("TTLs", function()
        it("should store data with a TTL", function()
            local instance = Kache.new(1)

            instance:Set("key", "value")
            expect(instance:Get("key")).to.equal("value")
            task.wait(1)
            expect(instance:Get("key")).to.equal(nil)
        end)

        it("should be able to act like an expiring dictionary", function()
            local instance = Kache.new(1)

            instance.key1 = "value"
            expect(instance.key1).to.equal("value")
            task.wait(1)
            expect(instance.key1).to.equal(nil)
        end)

        it("should have expiring defaults if they're persisted", function()
            local instance = Kache.new(1)

            expect(instance:Get("key", "default", true)).to.equal("default")
            expect(instance.key).to.equal("default")
            task.wait(1)
            expect(instance.key).to.equal(nil)
        end)

        it("should override TTLs if one is provided", function()
            local instance = Kache.new(1)

            instance.key1 = "value"
            instance:Set("key2", "value", 2)

            expect(instance.key1).to.equal("value")
            expect(instance.key2).to.equal("value")
            task.wait(1)
            expect(instance.key1).to.equal(nil)
            expect(instance.key2).to.equal("value")
            task.wait(1) -- would've waited 2 seconds at this point, past the TTL
            expect(instance.key2).to.equal(nil)
        end)
    end)

    describe("Sharing", function()
        it("should share instances", function()
            expect(Kache.shared("UNIT_TEST")).to.equal(Kache.shared("UNIT_TEST"))
        end)

        it("should store the same data in shared instances", function()
            local inst1 = Kache.shared("UNIT_TEST_1")
            local inst2 = Kache.shared("UNIT_TEST_1")

            inst1.data = "abcdefg"
            expect(inst2.data).to.equal("abcdefg")
        end)

        it("should not share instances if the instances are not named the same", function()
            expect(Kache.shared("UNIT_TEST")).never.to.equal(Kache.shared("UNIT_TEST_2"))
        end)

        it("should share cross-server instances", function()
            expect(Kache.crossServer("UNIT_TEST")).to.equal(Kache.crossServer("UNIT_TEST"))
        end)

        it("should not share cross-server instances if the instances are not named the same", function()
            expect(Kache.crossServer("UNIT_TEST")).never.to.equal(Kache.crossServer("UNIT_TEST_2"))
        end)

        it("should not share cross-server and regular shared instances", function()
            expect(Kache.shared("UNIT_TEST")).never.to.equal(Kache.crossServer("UNIT_TEST"))
        end)
    end)

    describe("Events", function()
        it("should fire an event whenever an item is put into cache", function()
            local instance = Kache.new()

            task.delay(1, function()
                instance.key1 = true
            end)

            local event, key, value, expiry = instance:Wait()

            expect(event).to.equal(Kache.Enum.Event.Set)
            expect(key).to.equal("key1")
            expect(value).to.equal(true)
            expect(expiry).to.equal(nil)
        end)
    end)
end