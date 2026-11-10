module Pos
  class AssignSessionCycle
    def self.apply_to_new(session)
      cycle, length = next_for(session.client)
      session.cycle = cycle
      session.cycle_length = length
    end

    def self.readjust(client)
      cycle = 1
      length = numbered_lengths.first

      client.sessions.order(:session_date, :id).each do |session|
        session.update!(cycle: cycle, cycle_length: length)
        cycle, length = advance(cycle, length)
      end

      sync_client(client)
    end

    def self.sync_client(client)
      latest = latest_session(client)
      client.update!(cycle: latest&.cycle, cycle_length: latest&.cycle_length)
    end

    def self.next_for(client)
      latest = latest_session(client)
      return [1, numbered_lengths.first] if latest.nil? || latest.cycle.nil?

      advance(latest.cycle, latest.cycle_length)
    end

    def self.advance(cycle, cycle_length)
      cycle = cycle.to_i
      lengths = lengths_for(cycle)
      index = lengths.index(cycle_length.to_s)

      if index.nil? || index == lengths.length - 1
        next_cycle = cycle + 1
        [next_cycle, lengths_for(next_cycle).first]
      else
        [cycle, lengths[index + 1]]
      end
    end

    def self.lengths_for(cycle)
      if cycle.even?
        CYCLE_LENGTHS
      else
        numbered_lengths
      end
    end

    def self.numbered_lengths
      CYCLE_LENGTHS.reject { |length| length == BONUS_CYCLE_LENGTH }
    end

    def self.latest_session(client)
      client.sessions.order(session_date: :desc, id: :desc).first
    end
  end
end
