require 'rspec'
require 'json'
require_relative '../src/request.rb'

module Secrets
  EXPECTED_APP_ID = 'blah'
end

describe Request do
  describe 'user id' do
    it 'should extract the user id from intent requests' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' }, user: { userId: 'userid' } },
        request: { type: 'AudioPlayer.ABC' }
      })
      request = Request.extract_from_request_body(body)
      expect(request.user_id).to eq('userid')
    end

    it 'should extract the user id from non-intent requests' do
      body = JSON.generate({
        context: { System: {
          application: { applicationId: 'blah' },
          user: { userId: 'userid' }
        } },
        request: { type: 'AudioPlayer.ABC' }
      })
      request = Request.extract_from_request_body(body)
      expect(request.user_id).to eq('userid')
    end
  end

  describe 'valid?' do
    it 'should mark empty request bodies as invalid' do
      expect(Request.extract_from_request_body('').valid?).to be(false)
    end

    it 'should mark unexpected app ids as invalid' do
      body = JSON.generate({
        session: { application: { applicationId: 'invalid' }, user: { userId: 'userid' } },
        request: { type: 'AudioPlayer.ABC' }
      })
      expect(Request.extract_from_request_body(body).valid?).to be(false)
    end

    it 'should mark expected app ids as valid' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' }, user: { userId: 'userid' } },
        request: { type: 'AudioPlayer.ABC' }
      })
      expect(Request.extract_from_request_body(body).valid?).to be(true)
    end

    it 'should extract the app id from context if it\'s not an intent request' do
      body = JSON.generate({
        context: { System: {
          application: { applicationId: 'blah' },
          user: { userId: 'userid' }
        } },
        request: { type: 'AudioPlayer.ABC' }
      })
      expect(Request.extract_from_request_body(body).valid?).to be(true)
    end

    it 'should mark an invalid request_type as invalid' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' }, user: { userId: 'userid' } },
        request: { type: 'YoIdk' }
      })
      expect(Request.extract_from_request_body(body).valid?).to be(false)
    end
  end

  describe 'request_type' do
    it 'should use any AudioPlayer request as the request type' do
      body = JSON.generate({
        context: { System: {
          application: { applicationId: 'blah' },
          user: { userId: 'userid' }
        } },
        request: { type: 'AudioPlayer.ABC' }
      })
      expect(Request.extract_from_request_body(body).request_type).to eq('AudioPlayer.ABC')
    end

    it 'should use any the intent name for any intent request as the request type' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' }, user: { userId: 'userid' } },
        request: { type: 'IntentRequest', intent: { name: 'IntentName' } }
      })
      expect(Request.extract_from_request_body(body).request_type).to eq('IntentName')
    end

    it 'should use nil as the request type for unexpected cases' do
      body = JSON.generate({
        session: { application: { applicationId: 'blah' }, user: { userId: 'userid' } },
        request: { type: 'YoIdk' }
      })
      expect(Request.extract_from_request_body(body).request_type).to be(nil)
    end
  end

  describe 'offset_in_milliseconds' do
    it 'should extract the offset_in_milliseconds if it\'s there' do
      body = JSON.generate({
        context: {
          AudioPlayer: { offsetInMilliseconds: 500 },
          System: {
            application: { applicationId: 'blah' },
            user: { userId: 'userid' }
          }
        },
        request: { type: 'AudioPlayer.ABC' }
      })
      request = Request.extract_from_request_body(body)
      expect(request.offset_in_milliseconds).to eq(500)
    end

    it 'should be 0 otherwise' do
      body = JSON.generate({
        context: { System: {
          application: { applicationId: 'blah' },
          user: { userId: 'userid' }
        } },
        request: { type: 'AudioPlayer.ABC' }
      })
      request = Request.extract_from_request_body(body)
      expect(request.offset_in_milliseconds).to eq(0)
    end
  end

  describe 'token' do
    it 'should extract the token if it\'s there' do
      body = JSON.generate({
        context: {
          AudioPlayer: { offsetInMilliseconds: 500, token: 'hi' },
          System: {
            application: { applicationId: 'blah' },
            user: { userId: 'userid' }
          }
        },
        request: { type: 'AudioPlayer.ABC' }
      })
      request = Request.extract_from_request_body(body)
      expect(request.token).to eq('hi')
    end

    it 'should be nil otherwise' do
      body = JSON.generate({
        context: { System: {
          application: { applicationId: 'blah' },
          user: { userId: 'userid' }
        } },
        request: { type: 'AudioPlayer.ABC' }
      })
      request = Request.extract_from_request_body(body)
      expect(request.token).to be(nil)
    end
  end
end
