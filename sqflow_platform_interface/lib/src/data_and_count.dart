abstract class IResult<T> {
  List<T> data = [];
}

class Result<T> implements IResult<T> {
  Result({required this.data});

  @override
  List<T> data;
}

class ResultWithCount<T> implements IResult<T> {
  final int count;

  ResultWithCount({required this.data, required this.count});

  @override
  List<T> data;
}
