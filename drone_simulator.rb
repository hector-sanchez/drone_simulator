require 'forwardable'

require './drone.rb'

class DroneSimulator
    extend Forwardable
    
    def_delegators :drone, 
                    :status, 
                    :power_on, 
                    :power_off, 
                    :take_off,
                    :move_forward,
                    :move_back,
                    :move_left,
                    :move_right,
                    :move_up,
                    :move_down,
                    :stabilize,
                    :land
    
    
    attr_reader :drone
    
    def initialize(drone)
        @drone = drone
        drone.power_on
    end
end
