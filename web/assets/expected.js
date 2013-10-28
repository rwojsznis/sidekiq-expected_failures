 $(function() {
  function mapDataAttributes(element) {
    html = "";
    $.each(element.data(), function( key, value ) {
      html += "<tr><th>Argument no. " + key + "</th><td>" + value + "</td></tr>";
    });
    return html;
  }

  $('#expected tbody td:last-child > a').live('click', function(e){
    $('#job-details .modal-body table tbody').html(mapDataAttributes($(this)));
    $('#job-details').modal('show')
  });

  $('#filter-jobs select').live('change', function(e){
    $(this).parent('form').submit();
  });
 });
