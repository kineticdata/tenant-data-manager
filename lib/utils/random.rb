module Kinetic
  module Platform
    class Random

      # Symbols that are allowed by default
      DEFAULT_SYMBOLS = %w( ! @ % * ( ) { } [ ] )
      # Symbols that are represented as 7-bit ASCII
      SEVEN_BIT_ASCII_SYMBOLS = %w(! " # $ % & ' ( ) * + - . / : ; < = > ? @ [ \ ] & _ ` { | } ~)
      # Alpha-numeric characters that are respresented as 7-bit ASCII
      SEVEN_BIT_ASCII_ALPHANUM = 
        ('A'..'Z').to_a.concat(
          ('a'..'z').to_a).concat(
            ('0'..'9').to_a)

      # Generates a simple secret based on ASCII alpha-numeric characters,
      # and a few standard symbol characters.
      #
      # @param size [Fixnum] The length of the generated secret
      # @param allowed_symbols [Array] symbols to allow
      def self.simple(size = 20, allowed_symbols = DEFAULT_SYMBOLS)
        chars = (allowed_symbols || Array.new).concat(SEVEN_BIT_ASCII_ALPHANUM)
        (0...size).map { chars[rand(chars.size)] }.join
      end

    end
  end
end