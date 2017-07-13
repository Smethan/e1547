// e1547: A mobile app for browsing e926.net and friends.
// Copyright (C) 2017 perlatus <perlatus@e1547.email.vczf.io>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <http://www.gnu.org/licenses/>.

import 'dart:convert' show JsonEncoder;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show TextOverflow;
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, SystemChrome, SystemUiOverlay;

import 'package:logging/logging.dart' show Logger;
import 'package:url_launcher/url_launcher.dart' as url;
import 'package:zoomable_image/zoomable_image.dart' show ZoomableImage;

import 'persistence.dart' as persistence;

import 'src/e1547/post.dart' show Post;

// Main widget for presenting and interacting with individual posts.
class PostWidget extends StatefulWidget {
  final Post post;
  PostWidget(this.post, {Key key}) : super(key: key);

  @override
  State createState() => new _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  static final Logger _log = new Logger('PostWidget');

  _fullscreen(BuildContext ctx) async {
    SystemChrome.setEnabledSystemUIOverlays([SystemUiOverlay.bottom]);
    await Navigator.of(ctx).push(new MaterialPageRoute<Null>(
          builder: (ctx) => new ZoomableImage(
                new NetworkImage(widget.post.fileUrl),
                scale: 16.0,
              ),
        ));
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);
  }

  @override
  Widget build(BuildContext ctx) {
    Widget fullscreenButton = new Container(
      padding: const EdgeInsets.all(12.0),
      color: Colors.black38,
      child: const Icon(Icons.fullscreen),
    );

    Widget image = widget.post.fileExt == 'swf' || widget.post.fileExt == 'webm'
        ? new Container()
        : new Image.network(widget.post.sampleUrl);

    Widget content = new Stack(children: [
      new Center(child: image),
      new Positioned(
        right: 0.0,
        bottom: 0.0,
        child: fullscreenButton,
      ),
    ]);

    content = new Container(
      color: Colors.black,
      constraints: const BoxConstraints.expand(),
      child: content,
    );

    content = new GestureDetector(
      onTap: () {
        if (widget.post.fileExt == 'gif' || widget.post.fileExt == 'webm') {
          url.launch(widget.post.fileUrl);
        } else {
          _fullscreen(ctx);
        }
      },
      child: content,
    );

    content = new Flexible(child: content);

    return new Scaffold(
      body: new Padding(
          padding: new EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: new Column(mainAxisSize: MainAxisSize.min, children: [
            content,
            _buildButtonBar(ctx),
          ])),
    );
  }

  Widget _buildButtonBar(BuildContext ctx) {
    return new ButtonTheme.bar(
        child: new ButtonBar(
      alignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        new IconButton(
            icon: const Icon(Icons.favorite),
            tooltip: 'Add post to favorites',
            onPressed: () => _log.fine('pressed fav')),
        new IconButton(
            icon: const Icon(Icons.chat),
            tooltip: 'Go to comments',
            onPressed: () => _log.fine('pressed chat')),
        new IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'View in browser',
            onPressed: () => _viewInBrowserButtonOnPressed(ctx)),
        new IconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'More actions',
            onPressed: () =>
                showDialog(context: ctx, child: new _MoreDialog(widget.post))),
      ],
    ));
  }

  _viewInBrowserButtonOnPressed(BuildContext ctx) {
    SimpleDialog dialog;
    Widget title = new ListTile(
      leading: const Icon(Icons.open_in_browser),
      title: new Text('View post #${widget.post.id} in browser'),
    );

    List<Widget> children = <Widget>[
      new ListTile(
          title: new Text('View post'),
          onTap: () async {
            String host = await persistence.getHost();
            url.launch(widget.post.url(host).toString());
            Navigator.of(ctx).pop();
          }),
      new ListTile(
          title: new Text('View direct content'),
          onTap: () {
            url.launch(widget.post.fileUrl);
            Navigator.of(ctx).pop();
          }),
    ];

    dialog = new SimpleDialog(title: title, children: children);
    showDialog(context: ctx, child: dialog);
  }
}

// Preview of a post that appears in lists of posts. Mostly just the image.
class PostPreview extends StatelessWidget {
  static final Logger _log = new Logger('PostPreview');
  final Post post;
  final VoidCallback onPressed;
  PostPreview(this.post, {Key key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext ctx) => new GestureDetector(
      onTap: onPressed,
      child: new Card(
          child: new Column(
        children: <Widget>[
          _buildImagePreview(ctx),
          _buildPostInfo(ctx),
        ],
      )));

  Widget _buildImagePreview(BuildContext ctx) {
    Widget image = new Container(
      color: Colors.grey[800],
      constraints: const BoxConstraints.expand(),
      child: new Image.network(post.previewUrl, fit: BoxFit.contain),
    );

    Widget specialOverlayIcon;
    if (post.fileExt == 'gif') {
      _log.fine('post ${post.id} was gif');
      specialOverlayIcon = new Container(
        padding: EdgeInsets.zero,
        color: Colors.black38,
        child: const Icon(Icons.gif),
      );
    }

    Widget flexibleChild = specialOverlayIcon == null
        ? image
        : new Stack(children: [
            image,
            new Positioned(top: 0.0, right: 0.0, child: specialOverlayIcon),
          ]);

    return new Flexible(child: flexibleChild);
  }

  Widget _buildPostInfo(BuildContext ctx) {
    Widget info = new InfoSquare(
        post.score, post.favCount, post.hasComments, post.rating);

    Widget artists = new Text(
      post.artist.join(',\n'),
      style: new TextStyle(fontSize: 12.0),
      softWrap: false,
      overflow: TextOverflow.ellipsis,
    );

    return new Padding(
        padding: const EdgeInsets.all(10.0),
        child: new Column(children: [
          info,
          new Padding(
              padding: const EdgeInsets.only(top: 10.0), child: artists),
        ]));
  }
}

const double _infoSquareVerticalPadding = 3.0;
const double _infoSquareHorizontalPadding = 2.0;

//    <score>    <comments>
//    <favcount> <safety rating>
class InfoSquare extends StatelessWidget {
  final int score;
  final int favCount;
  final bool hasComments;
  final String rating;
  InfoSquare(this.score, this.favCount, this.hasComments, this.rating,
      {Key key})
      : super(key: key);

  // This builds a small icon followed by a text. Used for the info square.
  Widget _iconTextPair(IconData icon, String text) {
    return new Row(mainAxisSize: MainAxisSize.min, children: [
      new Padding(
          padding: const EdgeInsets.only(right: 3.0),
          child: IconTheme.merge(
            data: new IconThemeData(size: 12.0),
            child: new Icon(icon),
          )),
      new Text(text, style: new TextStyle(fontSize: 12.0)),
    ]);
  }

  @override
  Widget build(BuildContext ctx) {
    Widget scoreInfo = score >= 0
        ? _iconTextPair(Icons.arrow_upward, '+' + score.toString())
        : _iconTextPair(Icons.arrow_downward, score.toString());

    Widget commentsInfo =
        _iconTextPair(Icons.question_answer, hasComments ? '+' : '0');

    Widget favoritesInfo = _iconTextPair(Icons.favorite, favCount.toString());
    Widget ratingInfo = _iconTextPair(Icons.warning, rating);

    return new Table(
        // IntrinsicColumnWidth is expensive but also the only one that seems to work.
        defaultColumnWidth: const IntrinsicColumnWidth(),
        children: <TableRow>[
          new TableRow(children: [
            _padTopLeft(scoreInfo),
            _padTopRight(commentsInfo),
          ]),
          new TableRow(children: [
            _padBottomLeft(favoritesInfo),
            _padBottomRight(ratingInfo),
          ]),
        ]);
  }

  //
  // <AWFUL>
  //
  Widget _padTopLeft(Widget child) => new Padding(
        child: child,
        padding: const EdgeInsets.only(
            right: _infoSquareHorizontalPadding / 2.0,
            bottom: _infoSquareVerticalPadding / 2.0),
      );
  Widget _padTopRight(Widget child) => new Padding(
        child: child,
        padding: const EdgeInsets.only(
            left: _infoSquareHorizontalPadding / 2.0,
            bottom: _infoSquareVerticalPadding / 2.0),
      );
  Widget _padBottomLeft(Widget child) => new Padding(
        child: child,
        padding: const EdgeInsets.only(
            right: _infoSquareHorizontalPadding / 2.0,
            top: _infoSquareVerticalPadding / 2.0),
      );
  Widget _padBottomRight(Widget child) => new Padding(
        child: child,
        padding: const EdgeInsets.only(
            left: _infoSquareHorizontalPadding / 2.0,
            top: _infoSquareVerticalPadding / 2.0),
      );
  //
  // </AWFUL>
  //
}

class _MoreDialog extends StatelessWidget {
  final Post post;
  _MoreDialog(this.post);

  @override
  Widget build(BuildContext ctx) {
    return new SimpleDialog(title: new Text('post #${post.id}'), children: [
      _buildPostInfo(ctx),
      _buildCopy(ctx),
      _buildDownload(ctx),
    ]);
  }

  Widget _buildPostInfo(BuildContext ctx) {
    return new ListTile(
      leading: const Icon(Icons.info_outline),
      title: new Text('Info'),
      onTap: () => showDialog(
            context: ctx,
            child: new SimpleDialog(
              title: new Text('post #${post.id} info'),
              children: <Widget>[
                new TextField(
                    maxLines: 15,
                    decoration: new InputDecoration(hideDivider: true),
                    style: new TextStyle(fontFamily: 'Courier'),
                    controller: new TextEditingController(
                        text:
                            new JsonEncoder.withIndent('  ').convert(post.raw)))
              ],
            ),
          ),
    );
  }

  Widget _buildCopy(BuildContext ctx) {
    return new ListTile(
      leading: const Icon(Icons.content_copy),
      title: new Text('Copy...'),
      trailing: const Icon(Icons.arrow_right),
      onTap: () => _showCopyDialog(ctx),
    );
  }

  _showCopyDialog(BuildContext ctx) {
    Widget dialog;

    Widget title = new ListTile(
        leading: const Icon(Icons.content_copy),
        title: new Text('Copy from post #${post.id}'));

    Widget copyLink = new ListTile(
        title: new Text('Copy link'),
        onTap: () async {
          String host = await persistence.getHost();
          String link = post.url(host).toString();
          _copyAndPopPop(ctx, link);
        });

    Widget copyDirectLink = new ListTile(
        title: new Text('Copy direct link'),
        onTap: () => _copyAndPopPop(ctx, post.fileUrl));

    dialog =
        new SimpleDialog(title: title, children: [copyLink, copyDirectLink]);

    showDialog(context: ctx, child: dialog);
  }

  _copyAndPopPop(BuildContext ctx, String text) async {
    await Clipboard.setData(new ClipboardData(text: text));
    Navigator.of(ctx).pop();
    Navigator.of(ctx).pop();
  }

  // TODO: Android-only, make sure this is hidden on iOS
  Widget _buildDownload(BuildContext ctx) {
    return new ListTile(
        leading: const Icon(Icons.file_download),
        title: new Text('Download'),
        onTap: () => showDialog(
            context: ctx,
            child: new SimpleDialog(
              title: new Text('post #${post.id} download'),
              children: <Widget>[
                const LinearProgressIndicator(),
                new TextField(
                    controller: new TextEditingController(
                        text:
                            '${post.artist.join("+")}#${post.id}.${post.fileExt}')),
              ],
            )));
  }
}

class PostGrid extends StatefulWidget {
  final List<Post> posts;
  final VoidCallback onLoadMore;
  PostGrid(this.posts, {Key key, this.onLoadMore}) : super(key: key);

  @override
  State createState() => new _PostGridState();
}

class _PostGridState extends State<PostGrid> {
  final Logger _log = new Logger('PostGrid');

  @override
  Widget build(BuildContext ctx) {
    return new GridView.custom(
      gridDelegate: new SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150.0,
        childAspectRatio: 3 / 5,
      ),
      childrenDelegate: new SliverChildBuilderDelegate(_itemBuilder),
    );
  }

  Widget _itemBuilder(BuildContext ctx, int i) {
    _log.fine('loading post $i');
    if (i > widget.posts.length) {
      return null;
    } else if (i == widget.posts.length) {
      return new RaisedButton(
        child: new Text('load more'),
        onPressed: widget.onLoadMore,
      );
    }

    return new PostPreview(widget.posts[i], onPressed: () {
      Navigator.of(ctx).push(new MaterialPageRoute<Null>(
            builder: (ctx) => new PostSwipe(widget.posts, startingIndex: i),
          ));
    });
  }
}

class PostSwipe extends StatefulWidget {
  final List<Post> posts;
  final int startingIndex;
  PostSwipe(this.posts, {Key key, this.startingIndex = 0}) : super(key: key);

  @override
  State createState() => new _PostSwipeState();
}

class _PostSwipeState extends State<PostSwipe> {
  @override
  Widget build(BuildContext ctx) {
    return new PageView.builder(
        controller: new PageController(initialPage: widget.startingIndex),
        itemBuilder: (ctx, i) {
          return i < widget.posts.length
              ? new PostWidget(widget.posts[i])
              : null;
        });
  }
}
