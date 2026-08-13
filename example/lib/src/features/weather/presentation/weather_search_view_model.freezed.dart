// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_search_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeatherSearchState {

 List<String> get suggestions; WeatherSearchStatus get searchStatus;
/// Create a copy of WeatherSearchState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherSearchStateCopyWith<WeatherSearchState> get copyWith => _$WeatherSearchStateCopyWithImpl<WeatherSearchState>(this as WeatherSearchState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherSearchState&&const DeepCollectionEquality().equals(other.suggestions, suggestions)&&(identical(other.searchStatus, searchStatus) || other.searchStatus == searchStatus));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(suggestions),searchStatus);

@override
String toString() {
  return 'WeatherSearchState(suggestions: $suggestions, searchStatus: $searchStatus)';
}


}

/// @nodoc
abstract mixin class $WeatherSearchStateCopyWith<$Res>  {
  factory $WeatherSearchStateCopyWith(WeatherSearchState value, $Res Function(WeatherSearchState) _then) = _$WeatherSearchStateCopyWithImpl;
@useResult
$Res call({
 List<String> suggestions, WeatherSearchStatus searchStatus
});




}
/// @nodoc
class _$WeatherSearchStateCopyWithImpl<$Res>
    implements $WeatherSearchStateCopyWith<$Res> {
  _$WeatherSearchStateCopyWithImpl(this._self, this._then);

  final WeatherSearchState _self;
  final $Res Function(WeatherSearchState) _then;

/// Create a copy of WeatherSearchState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? suggestions = null,Object? searchStatus = null,}) {
  return _then(_self.copyWith(
suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>,searchStatus: null == searchStatus ? _self.searchStatus : searchStatus // ignore: cast_nullable_to_non_nullable
as WeatherSearchStatus,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherSearchState].
extension WeatherSearchStatePatterns on WeatherSearchState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherSearchState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherSearchState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherSearchState value)  $default,){
final _that = this;
switch (_that) {
case _WeatherSearchState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherSearchState value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherSearchState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> suggestions,  WeatherSearchStatus searchStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherSearchState() when $default != null:
return $default(_that.suggestions,_that.searchStatus);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> suggestions,  WeatherSearchStatus searchStatus)  $default,) {final _that = this;
switch (_that) {
case _WeatherSearchState():
return $default(_that.suggestions,_that.searchStatus);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> suggestions,  WeatherSearchStatus searchStatus)?  $default,) {final _that = this;
switch (_that) {
case _WeatherSearchState() when $default != null:
return $default(_that.suggestions,_that.searchStatus);case _:
  return null;

}
}

}

/// @nodoc


class _WeatherSearchState implements WeatherSearchState {
  const _WeatherSearchState({final  List<String> suggestions = const [], this.searchStatus = WeatherSearchStatus.idle}): _suggestions = suggestions;
  

 final  List<String> _suggestions;
@override@JsonKey() List<String> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}

@override@JsonKey() final  WeatherSearchStatus searchStatus;

/// Create a copy of WeatherSearchState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherSearchStateCopyWith<_WeatherSearchState> get copyWith => __$WeatherSearchStateCopyWithImpl<_WeatherSearchState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherSearchState&&const DeepCollectionEquality().equals(other._suggestions, _suggestions)&&(identical(other.searchStatus, searchStatus) || other.searchStatus == searchStatus));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_suggestions),searchStatus);

@override
String toString() {
  return 'WeatherSearchState(suggestions: $suggestions, searchStatus: $searchStatus)';
}


}

/// @nodoc
abstract mixin class _$WeatherSearchStateCopyWith<$Res> implements $WeatherSearchStateCopyWith<$Res> {
  factory _$WeatherSearchStateCopyWith(_WeatherSearchState value, $Res Function(_WeatherSearchState) _then) = __$WeatherSearchStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> suggestions, WeatherSearchStatus searchStatus
});




}
/// @nodoc
class __$WeatherSearchStateCopyWithImpl<$Res>
    implements _$WeatherSearchStateCopyWith<$Res> {
  __$WeatherSearchStateCopyWithImpl(this._self, this._then);

  final _WeatherSearchState _self;
  final $Res Function(_WeatherSearchState) _then;

/// Create a copy of WeatherSearchState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? suggestions = null,Object? searchStatus = null,}) {
  return _then(_WeatherSearchState(
suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>,searchStatus: null == searchStatus ? _self.searchStatus : searchStatus // ignore: cast_nullable_to_non_nullable
as WeatherSearchStatus,
  ));
}


}

// dart format on
