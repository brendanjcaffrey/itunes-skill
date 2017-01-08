require 'rspec'
require 'sqlite3'
require_relative '../src/control_intents.rb'
require_relative '../src/library.rb'

describe ControlIntents do
  before :each do
    Database.create_test_database
    @db = Database.new
    @control_intents = ControlIntents.new(@db)
    @builder = instance_double('ResponseBuilder')
    @user_id_request = Request.new(nil, 'USERID', nil, nil, nil)

    @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
    @db.set_is_next_track_enqueued('USERID', true)
    expect(@db.is_next_track_enqueued?('USERID')).to be(true)
  end

  def expect_current_track_and_offset(track_id, offset)
    track_and_offset = @db.get_current_track_and_offset('USERID')
    expect(track_and_offset.track_id).to eq(track_id)
    expect(track_and_offset.offset_in_milliseconds).to eq(offset)
  end

  context 'on_loop' do
    it 'should respond that it\'s unsupported' do
      expect(@builder).to receive(:add_plain_text_speech)
      @control_intents.on_loop(@user_id_request, @builder, true)
    end
  end

  context 'on_next' do
    it 'should go to the next track, update the offset and clear the enqueued flag' do
      expect(Library).to receive(:get_start_milliseconds_for_track_id).with('TRACK1').and_return(101)
      expect(@builder).to receive(:add_play_directive).with('USERID', 'TRACK1', 101)

      @control_intents.on_next(@user_id_request, @builder)

      expect(@db.is_next_track_enqueued?('USERID')).to be(false)
      expect_current_track_and_offset('TRACK1', 101)
    end
  end

  context 'on_pause' do
    it 'should store the offset from the request, clear the enqueued flag and clear the queue/stop' do
      expect(@builder).to receive(:add_clear_enqueued_and_stop_directives)
      @control_intents.on_pause(Request.new(nil, 'USERID', nil, 250, nil), @builder)

      expect(@db.is_next_track_enqueued?('USERID')).to be(false)
      expect_current_track_and_offset('TRACK0', 250)
    end
  end

  context 'on_previous' do
    it 'should go to the next track, update the offset and clear the enqueued flag' do
      expect(Library).to receive(:get_start_milliseconds_for_track_id).with('TRACK2').and_return(102)
      expect(@builder).to receive(:add_play_directive).with('USERID', 'TRACK2', 102)

      @control_intents.on_previous(@user_id_request, @builder)

      expect(@db.is_next_track_enqueued?('USERID')).to be(false)
      expect_current_track_and_offset('TRACK2', 102)
    end
  end

  context 'on_repeat' do
    it 'should respond that it\'s unsupported' do
      expect(@builder).to receive(:add_plain_text_speech)
      @control_intents.on_repeat(@user_id_request, @builder)
    end
  end

  context 'on_shuffle' do
    it 'should respond that it\'s unsupported' do
      expect(@builder).to receive(:add_plain_text_speech)
      @control_intents.on_shuffle(@user_id_request, @builder, true)
    end
  end

  context 'on_start_over' do
    it 'should start the current track over, update the offset and clear the enqueued flag' do
      expect(Library).to receive(:get_start_milliseconds_for_track_id).with('TRACK0').and_return(100)
      expect(@builder).to receive(:add_play_directive).with('USERID', 'TRACK0', 100)

      @control_intents.on_start_over(@user_id_request, @builder)

      expect(@db.is_next_track_enqueued?('USERID')).to be(false)
      expect_current_track_and_offset('TRACK0', 100)
    end
  end

  context 'on_stop' do
    it 'should store the offset from the library, clear the enqueued flag and clear the queue' do
      expect(@builder).to receive(:add_clear_all_directive)
      expect(Library).to receive(:get_start_milliseconds_for_track_id).with('TRACK0').and_return(200)

      @control_intents.on_stop(Request.new(nil, 'USERID', nil, 250, nil), @builder)

      expect(@db.is_next_track_enqueued?('USERID')).to be(false)
      expect_current_track_and_offset('TRACK0', 200)
    end
  end
end
