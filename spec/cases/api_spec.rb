require 'spec_helper'

describe "Koala::Facebook::API" do
  before(:each) do
    @service = Koala::Facebook::API.new
  end

  it "should not include an access token if none was given" do
    Koala.should_receive(:make_request).with(
      anything,
      hash_not_including('access_token' => 1),
      anything,
      anything
    ).and_return(Koala::Response.new(200, "", ""))

    @service.api('anything')
  end

  it "should include an access token if given" do
    token = 'adfadf'
    service = Koala::Facebook::API.new token

    Koala.should_receive(:make_request).with(
      anything,
      hash_including('access_token' => token),
      anything,
      anything
    ).and_return(Koala::Response.new(200, "", ""))

    service.api('anything')
  end

  it "should have an attr_reader for access token" do
    token = 'adfadf'
    service = Koala::Facebook::API.new token
    service.access_token.should == token
  end

  it "should get the attribute of a Koala::Response given by the http_component parameter" do
    http_component = :method_name

    response = mock('Mock KoalaResponse', :body => '', :status => 200)
    response.should_receive(http_component).and_return('')

    Koala.stub(:make_request).and_return(response)

    @service.api('anything', {}, 'get', :http_component => http_component)
  end

  it "should return the body of the request as JSON if no http_component is given" do
    response = stub('response', :body => 'body', :status => 200)
    Koala.stub(:make_request).and_return(response)

    json_body = mock('JSON body')
    MultiJson.stub(:decode).and_return([json_body])

    @service.api('anything').should == json_body
  end

  it "should execute an error checking block if provided" do
    body = '{}'
    Koala.stub(:make_request).and_return(Koala::Response.new(200, body, {}))

    yield_test = mock('Yield Tester')
    yield_test.should_receive(:pass)

    @service.api('anything', {}, "get") do |arg|
      yield_test.pass
      arg.should == MultiJson.decode(body)
    end
  end

  it "should raise an API error if the HTTP response code is greater than or equal to 500" do
    Koala.stub(:make_request).and_return(Koala::Response.new(500, 'response body', {}))

    lambda { @service.api('anything') }.should raise_exception(Koala::Facebook::APIError)
  end

  it "should handle rogue true/false as responses" do
    Koala.should_receive(:make_request).and_return(Koala::Response.new(200, 'true', {}))
    @service.api('anything').should be_true

    Koala.should_receive(:make_request).and_return(Koala::Response.new(200, 'false', {}))
    @service.api('anything').should be_false
  end

  describe "with regard to leading slashes" do
    it "should add a leading / to the path if not present" do
      path = "anything"
      Koala.should_receive(:make_request).with("/#{path}", anything, anything, anything).and_return(Koala::Response.new(200, 'true', {}))
      @service.api(path)
    end

    it "shouldn't change the path if a leading / is present" do
      path = "/anything"
      Koala.should_receive(:make_request).with(path, anything, anything, anything).and_return(Koala::Response.new(200, 'true', {}))
      @service.api(path)
    end
  end

  describe "with an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new(@token)
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI with an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI with an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end

  describe "without an access token" do
    before(:each) do
      @api = Koala::Facebook::API.new
    end

    it_should_behave_like "Koala RestAPI"
    it_should_behave_like "Koala RestAPI without an access token"

    it_should_behave_like "Koala GraphAPI"
    it_should_behave_like "Koala GraphAPI without an access token"
    it_should_behave_like "Koala GraphAPI with GraphCollection"
  end
end
