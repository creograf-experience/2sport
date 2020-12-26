tinymce.PluginManager.add('filemanager', function(editor, url) {
  editor.addButton('filemanager', {
    text: 'File manager',
    icon: false,
    onclick: function() {
      editor.windowManager.open({
        title: 'Выберите файл',
        url: '/angular-templates/file-manager-popup.html',
        onsubmit: function(e) {
          editor.insertContent('Title: ' + e.data.title);
        }
      });
    }
  });
});
