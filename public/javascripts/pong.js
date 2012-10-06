// Generated by CoffeeScript 1.3.3
(function() {
  var Game;

  window.Game = Game = (function() {

    function Game() {
      this.up_pressed = false;
      this.down_pressed = false;
      this.y_positions = [10, 10];
      this.side = 0;
      this.enemy_side = 1;
      this.ball_pos = [100, 100];
      this.angle = (20 + Math.random() * 50) * Math.PI / 180;
      this.canvas_width = 780;
      this.canvas_height = 440;
      this.racket_height = 55;
      this.racket_width = 10;
      this.ball_size = 8;
      this.dy = 5;
      this.dt = 20;
      this.dt_in_sec = this.dt / 1000;
      this.ball_v = 200;
      this.key_left = 37;
      this.key_up = 38;
      this.key_right = 39;
      this.key_down = 40;
      this.key_space = 32;
      this.dir_up = -1;
      this.dir_idle = 0;
      this.dir_down = 1;
      this.players_start_pos = [[10, 80], [760, this.canvas_height - 80 - this.racket_height]];
      this.racket_color = '#fff';
    }

    Game.prototype.drawRacket = function(x, y, color) {
      this.ctx.fillStyle = color;
      return this.ctx.fillRect(x, y, this.racket_width, this.racket_height);
    };

    Game.prototype.drawBall = function(x, y) {
      this.ctx.fillStyle = "rgb(200, 200, 200)";
      return this.ctx.fillRect(x, y, this.ball_size, this.ball_size);
    };

    Game.prototype.drawBoard = function() {
      this.ctx.clearRect(0, 0, this.canvas_width, this.canvas_height);
      this.ctx.fillStyle = "rgb(200, 200, 200)";
      this.ctx.fillRect(389, 5, 1, 430);
      this.drawRacket(this.players_start_pos[this.side][0], this.y_positions[this.side], this.racket_color);
      this.drawRacket(this.players_start_pos[this.enemy_side][0], this.y_positions[this.enemy_side], this.racket_color);
      return this.drawBall(this.ball_pos[0], this.ball_pos[1]);
    };

    Game.prototype.gameLoop = function() {
      this.updateState();
      return this.drawBoard();
    };

    Game.prototype.updateState = function() {
      return this.updateBall();
    };

    Game.prototype.updateBall = function() {
      var ball_in_racket, ds;
      ds = this.ball_v * this.dt_in_sec;
      this.ball_pos[0] += ds * Math.cos(this.angle);
      this.ball_pos[1] += ds * Math.sin(this.angle);
      if (this.ball_pos[0] < 0) {
        this.ball_pos[0] = 0;
        this.angle = Math.PI - this.angle;
        return;
      }
      if (this.ball_pos[0] > this.canvas_width - this.ball_size) {
        this.ball_pos[0] = this.canvas_width - this.ball_size;
        this.angle = Math.PI - this.angle;
        return;
      }
      if (this.ball_pos[1] < 0) {
        this.ball_pos[1] = 0;
        this.angle = -this.angle;
        return;
      }
      if (this.ball_pos[1] > this.canvas_height - this.ball_size) {
        this.ball_pos[1] = this.canvas_height - this.ball_size;
        this.angle = -this.angle;
        return;
      }
      ball_in_racket = this.ball_pos[1] >= this.y_positions[0] && this.ball_pos[1] <= this.y_positions[0] + this.racket_height;
      if (this.ball_pos[0] < 20 && ball_in_racket) {
        this.ball_pos[0] = 20;
        this.angle = Math.PI - this.angle;
        return;
      }
      ball_in_racket = this.ball_pos[1] >= this.y_positions[1] && this.ball_pos[1] <= this.y_positions[1] + this.racket_height;
      if (this.ball_pos[0] > this.canvas_width - 20 && ball_in_racket) {
        this.ball_pos[0] = this.canvas_width - 20 - this.ball_size;
        this.angle = Math.PI - this.angle;
      }
    };

    Game.prototype.keyboardDown = function(evt) {
      switch (evt.which) {
        case this.key_down:
          this.down_pressed = true;
          this.up_pressed = false;
          return this.sendState(this.dir_down);
        case this.key_up:
          this.up_pressed = true;
          this.down_pressed = false;
          return this.sendState(this.dir_up);
      }
    };

    Game.prototype.keyboardUp = function(evt) {
      switch (evt.which) {
        case this.key_down:
          this.down_pressed = false;
          if (!this.up_pressed) {
            return this.sendState(this.dir_idle);
          }
          break;
        case this.key_up:
          this.up_pressed = false;
          if (!this.down_pressed) {
            return this.sendState(this.dir_idle);
          }
      }
    };

    Game.prototype.sendState = function(dir) {
      return this.socket.emit('state', {
        side: this.side,
        state: dir
      });
    };

    Game.prototype.startGame = function() {
      var canvas, self;
      canvas = document.getElementById('game_board_canvas');
      this.ctx = canvas.getContext('2d');
      self = this;
      return setInterval((function() {
        return self.gameLoop();
      }), this.dt);
    };

    Game.prototype.start = function(socket) {
      var self;
      self = this;
      this.socket = socket;
      socket.on('connect', function() {
        return console.log("Socket opened, Master!");
      });
      socket.on('joined', function(side) {
        self.side = side;
        self.enemy_side = side === 0 ? 1 : 0;
        $(window).on('keydown', function(e) {
          return self.keyboardDown(e);
        });
        return $(window).on('keyup', function(e) {
          return self.keyboardUp(e);
        });
      });
      socket.on('move', function(data) {
        self.y_positions = data.positions;
        return console.log("" + self.y_positions[self.side] + ", " + self.y_positions[self.enemy_side]);
      });
      socket.on('busy', function(data) {});
      socket.emit('join');
      return this.startGame();
    };

    return Game;

  })();

}).call(this);