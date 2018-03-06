 $(function() {
  function mapDataAttributes(element) {
    var html = "";
    $.each(element.data(), function( key, value ) {
      html += "<tr><th>Argument #" + key + "</th><td>" + value + "</td></tr>";
    });
    return html;
  }

  window.addEventListener("keydown", function (event) {
    if (event.keyCode === 114 || ((event.ctrlKey || event.metaKey) && event.keyCode === 70)) {
      $('#search').toggleClass('hidden').focus();
      event.preventDefault();
    }
  });

  $('#search').live('keyup', function(event) {
    var query = $(this).val().toLowerCase();
    if (query.length) {
      $('.search-warning').remove();
      $('#expected tbody tr').each(function(index) {
        if ($(this).find('[data-search*="' + query + '"]').length) {
          $(this).show();
        } else {
          $(this).hide();
        }
      });

      if (!($('#expected tbody tr:visible').length)) {
        $('#expected tbody').append('<tr class="search-warning"><td colspan="5">Nothing found!</td></tr>');
      }
    } else {
      $('#expected tbody tr').show();
    }
  });

  $('#expected tbody td:last-child > a').live('click', function(event){
    $('#job-details .modal-body table tbody').html(mapDataAttributes($(this)));
    $('#job-details .modal-title').text($(this).attr('title'));
    $('#job-details').modal('show');

    event.preventDefault();
  });

  $('#clear-jobs select').live('change', function(event) {
    $(this).parent('form').submit();
  });

  $('#filter-jobs select').live('change', function(event) {
    location.href = $(this).val();
  });
 });
