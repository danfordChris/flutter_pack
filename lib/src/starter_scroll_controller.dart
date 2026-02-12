// import 'package:flutter/material.dart';

// abstract class StarterPagination<T> {
//   final int? totalPages;
//   final int? perPage;
//   final int? currentPage;

//   StarterPagination({
//     this.totalPages,
//     this.perPage,
//     this.currentPage,
//   });
// }

// class StarterScrollController extends ScrollController {
//   final StarterPagination? _pagination;
//   int? _currentPage;

//   bool? _paginating;
//   bool get paginating => _paginating ?? false;

//   StarterScrollController(this._pagination);

//   ScrollController? get pagination {
//     addListener(() {
//       if (_paginating ?? false) return;
//       double nextPageTrigger = (0.8 * position.maxScrollExtent);
//       if (position.pixels > nextPageTrigger) {
//         _currentPage ??= 1;
//         _currentPage = _currentPage! + 1;
//         _paginate();
//       }
//     });
//     return this;
//   }

//   void _paginate() async {
//     try {
//       _paginating = true;
//       notifyListeners();
//       // await _pagination?.onRefresh(_currentPage ?? 0);
//     } catch (exception) {
//       _currentPage ??= 1;
//       _currentPage = _currentPage! - 1;
//     } finally {
//       _paginating = false;
//       notifyListeners();
//     }
//   }
// }
