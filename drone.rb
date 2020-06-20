require 'aasm'

require './engine.rb'
require './gyroscope.rb'
require './constants.rb'
require './errors.rb'

class Drone
    include ActiveModel::Validations
    include AASM
    
    validates_numericality_of :number_of_engines, greater_than: 0
    
    attr_accessor :number_of_engines
    
    def initialize(number_of_engines: 4)
        @number_of_engines = number_of_engines
    end
    
    aasm do
        state :off, initial: true
        state :on
        state :hovering
        state :moving
        
        event :power_on do
            before do
                engines.each {|engine| engine.power_on! }
            end
            
            error {|error| p error }
            
            transitions :to => :on, :from => :off, :if => :off?
        end
        
        event :hover do
            transitions :to => :hovering
        end
        
        event :move do
            transitions :from => :hovering, :to => :moving, :if => :hovering?
        end
        
        event :stabilize do
            before do 
                puts "Stabilizing..."
            end
            
            transitions :to => :hovering
        end
        
        event :power_off do
            before do
                engines.each {|engine| engine.power_off! }
            end
            
            transitions :to => :off, :unless => :off?
        end
    end
    
    def gyroscope
        @gyroscope ||= Gyroscope.new
    end
    
    def status
        return "on" if on?
        return "hovering" if hovering?
        return "moving" if moving?
        
        "off"
    end
    
    def take_off
        puts "Taking off..."
        power_up_engines
        gyroscope.velocify(:y, engine_avg_speed * Constants::ACCELERATION_FACTOR) # just making shit up to simulate velovity per power becaue ... I don't know
    rescue Errors::DistressError => error
        puts error.message
    rescue Errors::EngineOfflineError
        # throw away..for now
    end
    
    def move_forward
        puts "Accelerating forward..."
        power_up_engines
        velocify(direction: :z)
    end
    
    def move_back
        puts "Slowing down..."
        power_down_engines
        velocify(direction: :z)
    end
    
    def move_up
        puts "Ascending..."
        power_up_engines
        velocify(direction: :y)
    end
    
    def move_down
        puts "Descending..."
        power_down_engines
        velocify(direction: :y)
    end
    
    def move_left
        puts "Accelerating left..."
        power_up_engines
        velocify(direction: :x)
    end
    
    def move_right
        puts "Accelerating right..."
        power_down_engines
        velocify(direction: :x)
    end
    
    def land
        puts "Landing..."
        power_down_engines
        gyroscope.velocify(:y, 0)
    end
    
    private
    
    def velocify(direction:)
        # just making shit up to simulate velovity per power becaue ... I don't know
        gyroscope.velocify(direction, engine_avg_speed * Constants::ACCELERATION_FACTOR)
    end
    
    def power_up_engines
        # set the max power to 110 to simulate engine failure when power > 100
        engines.each do |engine| 
            begin
                engine.powerize(rand(Constants::START_UP_POWER..110)) 
            rescue Errors::DistressError, Errors::EngineOfflineError => error
                puts error.message
            end
        end
    end
    
    def power_down_engines
        engines.each{|engine| engine.powerize(engine.power_indicator / 2) }
    end
    
    def engine_avg_speed
        total_power = engines.inject(0) {|sum, engine| sum += engine.power_indicator}
        online_engines = engines.select {|engine| engine.on?}
        
        return 0 if online_engines.none?
        
        total_power / online_engines.count    
    end
    
    def engines_running?
        engines.any?(&:on?)
    end
    
    def engines
        @engines ||= (0...number_of_engines).map { Engine.new }
    end
end
    