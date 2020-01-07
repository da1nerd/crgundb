class Dup
    MAX = 1000
    AGE = 9 * 1000

    @dup : Hash(String, Time)
    @to : Bool

    def initialize
        @dup = {} of String => Time
        @to = false
    end

    def check(id : String): String|Bool
        return track(id) if @dup.has_key?(id)
        false
    end

    def track(id : String): String
        @dup[id] = Time.utc
        if !@to
            @to = true
            spawn do
                sleep AGE
                @dup.delete_if { |_, time| time >= Time.utc - AGE.milliseconds}
                @to = false
            end
        end
        id
    end

    def self.random
        Random.rand(32).to_s()[-1..-3]
    end
end