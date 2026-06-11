abstract class SearchEvent {}

class SearchProducts extends SearchEvent {
  final String query;
  SearchProducts(this.query);
}
class ClearSearch extends SearchEvent {}
