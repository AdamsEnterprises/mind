Accounts.onLogin (attempt) ->
  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    user:
      _id: attempt.user._id
    type: 'login'
    level: Activity.LEVEL.ADMIN
    data:
      type: attempt.type
      methodName: attempt.methodName
      clientAddress: attempt.connection.clientAddress
      userAgent: attempt.connection.httpHeaders['user-agent'] or null

Accounts.onLoginFailure (attempt) ->
  if attempt.user
    user =
      _id: attempt.user._id
  else
    user = null

  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    user: user
    type: 'loginFailure'
    level: Activity.LEVEL.ADMIN
    data:
      type: attempt.type
      methodName: attempt.methodName
      error: "#{attempt.error}"
      clientAddress: attempt.connection.clientAddress
      userAgent: attempt.connection.httpHeaders['user-agent'] or null

Accounts.onLogout (attempt) ->
  Activity.documents.insert
    timestamp: new Date()
    connection: attempt.connection.id
    user:
      _id: attempt.user._id
    type: 'logout'
    level: Activity.LEVEL.ADMIN
    data: null

MethodHooks.before 'Settings.changeUsername', (options) ->
  if @userId
    # We store current username away so that we can log it.
    @_oldUsername = Meteor.users.findOne(@userId, fields: username: 1)?.username or null

MethodHooks.after 'Settings.changeUsername', (options) ->
  if @userId
    user =
      _id: @userId
  else
    user = null

  if options.error
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'usernameChangeFailure'
      level: Activity.LEVEL.ADMIN
      data:
        error: "#{options.error}"
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null
  else
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'usernameChange'
      level: Activity.LEVEL.ADMIN
      data:
        oldUsername: @_oldUsername
        newUsername: options.arguments[0]
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null

MethodHooks.after 'changePassword', (options) ->
  if @userId
    user =
      _id: @userId
  else
    user = null

  if options.error
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'passwordChangeFailure'
      level: Activity.LEVEL.ADMIN
      data:
        error: "#{options.error}"
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null
  else
    Activity.documents.insert
      timestamp: new Date()
      connection: @connection.id
      user: user
      type: 'passwordChange'
      level: Activity.LEVEL.ADMIN
      data:
        clientAddress: @connection.clientAddress
        userAgent: @connection.httpHeaders['user-agent'] or null