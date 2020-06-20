require 'active_model'
require 'aasm'

require './errors.rb'
require './constants.rb'

class Engine
    include ActiveModel::Validations
    include AASM
    
    validates_numericality_of :power, greater_than_or_equal_to: 0, less_than_or_equal_to: 100
    
    def initialize
        self.power = 0
    end
    
    aasm do
        state :off, initial: true
        state :on
        state :offline
        
        event :power_on do
            before do
                self.power = Constants::START_UP_POWER
            end
            
            transitions :from => :off, :to => :on, :if => :off?
        end
        
        event :power_off do
            before do
                self.power = 0
            end
            
            transitions :from => :on, :to => :off, :if => :on?
        end
        
        event :take_offline do
            before do
                self.power = 0
            end
            
            transitions :to => :offline
        end
    end
    
    def power_indicator
        power
    end
    
    def powerize(target_power)
        raise Errors::EngineOfflineError, "Engine is offline." if offline?
        
        self.power = target_power
        
        if invalid?
            take_offline!
            raise Errors::DistressError, "Engine failure!" 
        end
    end
    
    def status
        return "on" if on?
        return "offline" if offline?
        
        "off"
    end
    
    private
    
    attr_accessor :power
end