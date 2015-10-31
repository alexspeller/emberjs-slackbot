require 'bundler/setup'

Bundler.require

CHANNEL = '#emberjs'
TIMEOUT = 5 * 60
debouncer = nil
last_user = nil


class Debouncer
  def initialize timeout, &block
    @timeout, @block = timeout, block
  end

  def trigger
    kill
    @thread = Thread.new do
      sleep @timeout
      @block.call
    end
  end

  def kill
    @thread.kill if @thread
  end

  def triggered?
    !!@thread
  end
end



bot = Cinch::Bot.new do
  configure do |c|
    c.server = "irc.freenode.org"
    c.channels = [CHANNEL]
    c.nick = "Slackbot"
    debouncer = Debouncer.new TIMEOUT do
      channel = channels.find{|c| c.name == CHANNEL}
      badge = Net::HTTP.get URI('https://ember-community-slackin.herokuapp.com/badge.svg')
      doc = Nokogiri::XML(badge)
      online_count = doc.search('text').last.inner_text.split('/').first

      channel.send "It looks like you asked a question and no-one replied. There are currently #{online_count} people online in slack, why not try there?"
      channel.send 'https://ember-community-slackin.herokuapp.com'
    end
  end


  on :message do |m|
    if m.message.include?('?') || (m.user.nick == last_user && debouncer.triggered?)
      puts "triggering debouncer on message #{m.message} from #{m.user.nick}"
      debouncer.trigger
    else
      puts "killing debouncer on message #{m.message} from #{m.user.nick}"
      debouncer.kill
    end

    last_user = m.user.nick
  end
end


bot.start
