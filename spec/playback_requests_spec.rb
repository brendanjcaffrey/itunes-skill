require 'rspec'
require 'sqlite3'
require_relative '../src/playback_requests.rb'
require_relative '../src/library.rb'

describe PlaybackRequests do
  before :each do
    Database.create_test_database
    @db = Database.new
    @playback_requests = PlaybackRequests.new(@db)
    @builder = instance_double('ResponseBuilder')
    @nil_request = Request.new(nil, nil, nil, nil, nil)

    @db.create_or_replace_user_playlist('USERID', ['TRACK0', 'TRACK1', 'TRACK2'])
    expect(@db.is_next_track_enqueued?('USERID')).to be(false)
  end

  context 'on_finished' do
    it 'should clear the response' do
      expect(@builder).to receive(:clear_response)
      @playback_requests.on_finished(@nil_request, @builder)
    end
  end

  context 'on_stopped' do
    it 'should clear the response' do
      expect(@builder).to receive(:clear_response)
      @playback_requests.on_stopped(@nil_request, @builder)
    end
  end

  context 'on_failed' do
    it 'should clear the response' do
      expect(@builder).to receive(:clear_response)
      @playback_requests.on_failed(@nil_request, @builder)
    end
  end

  context 'on_nearly_finished' do
    it 'should enqueue the next track if the token matches what\'s currently playing' do
      request = Request.new(nil, 'USERID', nil, 0, 'TRACK0')
      expect(Library).to receive(:get_start_milliseconds_for_track_id).with('TRACK1').and_return(1000)
      expect(@builder).to receive(:add_enqueue_directive).with('USERID', 'TRACK1', 'TRACK0', 1000)
      @playback_requests.on_nearly_finished(request, @builder)

      expect(@db.is_next_track_enqueued?('USERID')).to be(true)
    end

    it 'should ignore the request if the next track is enqueued already' do
      @db.set_is_next_track_enqueued('USERID', true)
      expect(@db.is_next_track_enqueued?('USERID')).to be(true)

      request = Request.new(nil, 'USERID', nil, 0, 'TRACK0')
      expect(@builder).to receive(:clear_response)
      @playback_requests.on_nearly_finished(request, @builder)

      expect(@db.is_next_track_enqueued?('USERID')).to be(true)
    end

    it 'should ignore the request if the current track doesn\'t match the token' do
      request = Request.new(nil, 'USERID', nil, 0, 'TRACK1')
      expect(@builder).to receive(:clear_response)
      @playback_requests.on_nearly_finished(request, @builder)
    end
  end

  context 'on_started' do
    before :each do
      expect(@builder).to receive(:clear_response)
    end

    it 'should ignore the request if the current track id is the same as the token' do
      request = Request.new(nil, 'USERID', nil, 0, 'TRACK0')
      @playback_requests.on_started(request, @builder)
    end

    it 'should ignore if the token isn\'t equal to the next track' do
      request = Request.new(nil, 'USERID', nil, 0, 'TRACK2')
      @playback_requests.on_started(request, @builder)
    end

    it 'should advance the playlist, clear the next track enqueued flag and add a play' do
      @db.set_is_next_track_enqueued('USERID', true)
      expect(@db.is_next_track_enqueued?('USERID')).to be(true)
      expect(Library).to receive(:add_play_for_track_id).with('TRACK0')

      request = Request.new(nil, 'USERID', nil, 0, 'TRACK1')
      @playback_requests.on_started(request, @builder)

      expect(@db.get_current_track_and_offset('USERID').track_id).to eq('TRACK1')
      expect(@db.is_next_track_enqueued?('USERID')).to be(false)
    end
  end
end
