exports.index = (req, res) ->
  res.render "index", title: "Polypong"

exports.about = (req, res) ->
  res.render "about", title: "About"

exports.loginPage = (req, res) ->
  res.render "login", title: "Log in"

exports.loginAction = (req, res) ->
  console.log "Tried to log in"
  console.log "login: #{req.body.login}"
  console.log "login: #{req.body.password}"
  res.render "index", title: "Polypong"
