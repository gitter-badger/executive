chai = require 'chai'
chai.should()
chai.use require 'chai-as-promised'

exec = require '../lib'

describe 'exec', ->
  it 'should accept Node.js style callbacks', (done) ->
    exec.quiet 'bash -c "echo 1"', (err, stdout, stderr) ->
      stdout.should.eq '1\n'
      done()

  it 'should expose Promise API', ->
    {stdout} = yield exec.quiet 'bash -c "echo 1"'
    stdout.should.eq '1\n'

  it 'should split commands on multiple lines', ->
    {stdout} = yield exec.quiet '''
    bash -c "echo 1"
    bash -c "echo 2"
    bash -c "echo 3"
    '''
    stdout.should.eq '1\n2\n3\n'

  it 'should buffer all stdout', (done) ->
    exec.quiet 'bash -c "echo 1"', (err, stdout, stderr) ->
      stdout.should.eq '1\n'
      done()

  it 'should buffer all stderr', (done) ->
    exec.quiet 'bash -c doesnotexist', (err, stdout, stderr) ->
      stderr.should.contain 'command not found'
      done()

  it 'should shell out if necessary', ->
    {stdout} = yield exec 'echo foo | cat'
    stdout.should.eq 'foo\n'

  describe 'promises', ->
    it 'should not reject non-zero status', ->
      {stdout, stderr, status} = yield exec.quiet 'bash -c doesnotexist'
      stdout.should.eq ''
      stderr.should.contain 'command not found'
      status.should.eq 127

    it 'should reject non-zero status with strict enabled', ->
      p = exec.quiet 'bash -c doesnotexist', strict: true
      yield p.should.be.rejectedWith Error

  describe 'interactive', ->
    it 'should not buffer output', ->
      {stdout, stderr} = yield exec.interactive 'bash -c "echo 1"'
      stdout.should.eq ''
      stderr.should.eq ''

      {stdout, stderr} = yield exec.interactive 'bash -c doesnotexist'
      stdout.should.eq ''
      stderr.should.eq ''

  describe 'sync', ->
    it 'should execute command synchronously', ->
      {stdout, stderr} = exec.sync 'bash -c "echo 1"'
      stdout.should.eq '1\n'
      stderr.should.eq ''

  describe 'parallel', ->
    it 'should execute commands in parallel', ->
      {stdout, stderr} = yield exec.parallel '''
      bash -c "sleep 1 && echo 1"
      bash -c "echo 2"
      bash -c "echo 3"
      '''
      stdout.should.eq '2\n3\n1\n'
      stderr.should.eq ''
