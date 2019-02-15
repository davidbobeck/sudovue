$().ready(function() {
  let orig_background_color = 'crimson';
  let brush_color = 'crimson';
  let brush_text = '1';

  $('.cell.board').on('mouseenter', function(event) {
    orig_background_color = $(this).css('background');
    $(this).css('background', brush_color);
  });

  $('.cell.board').on('mouseout', function(event) {
    $(this).css('background', orig_background_color);
  });

  $('.cell.board').on('click', function(event) {
    $(this).css('background', brush_color);
    $(this).text(brush_text);
    orig_background_color = brush_color;
  });

  $('.cell.brush').on('click', function(event) {
    brush_color = $(this).css('background');
    brush_text = $(this).text();
  });

  $('.clear-button').on('click', function(event) {
    $('.cell.board').css('background', 'white');
    $('.cell.board').text('');
  });

  $('.run-button').on('click', function(event) {
    $('.cell.board').each(function() {
      if ($(this).text().length > 0) {
        alert($(this).attr('id') + " has value " + $(this).text());
      }
    });
  });
})
