// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weather_view_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeatherState {

 List<String> get suggestions; Weather? get weather; WeatherSearchStatus get searchStatus; WeatherLoadStatus get loadStatus; String get requestedCity;
/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherStateCopyWith<WeatherState> get copyWith => _$WeatherStateCopyWithImpl<WeatherState>(this as WeatherState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherState&&const DeepCollectionEquality().equals(other.suggestions, suggestions)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.searchStatus, searchStatus) || other.searchStatus == searchStatus)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.requestedCity, requestedCity) || other.requestedCity == requestedCity));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(suggestions),weather,searchStatus,loadStatus,requestedCity);

@override
String toString() {
  return 'WeatherState(suggestions: $suggestions, weather: $weather, searchStatus: $searchStatus, loadStatus: $loadStatus, requestedCity: $requestedCity)';
}


}

/// @nodoc
abstract mixin class $WeatherStateCopyWith<$Res>  {
  factory $WeatherStateCopyWith(WeatherState value, $Res Function(WeatherState) _then) = _$WeatherStateCopyWithImpl;
@useResult
$Res call({
 List<String> suggestions, Weather? weather, WeatherSearchStatus searchStatus, WeatherLoadStatus loadStatus, String requestedCity
});




}
/// @nodoc
class _$WeatherStateCopyWithImpl<$Res>
    implements $WeatherStateCopyWith<$Res> {
  _$WeatherStateCopyWithImpl(this._self, this._then);

  final WeatherState _self;
  final $Res Function(WeatherState) _then;

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? suggestions = null,Object? weather = freezed,Object? searchStatus = null,Object? loadStatus = null,Object? requestedCity = null,}) {
  return _then(_self.copyWith(
suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>,weather: freezed == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as Weather?,searchStatus: null == searchStatus ? _self.searchStatus : searchStatus // ignore: cast_nullable_to_non_nullable
as WeatherSearchStatus,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as WeatherLoadStatus,requestedCity: null == requestedCity ? _self.requestedCity : requestedCity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [WeatherState].
extension WeatherStatePatterns on WeatherState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeatherState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeatherState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeatherState value)  $default,){
final _that = this;
switch (_that) {
case _WeatherState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeatherState value)?  $default,){
final _that = this;
switch (_that) {
case _WeatherState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> suggestions,  Weather? weather,  WeatherSearchStatus searchStatus,  WeatherLoadStatus loadStatus,  String requestedCity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherState() when $default != null:
return $default(_that.suggestions,_that.weather,_that.searchStatus,_that.loadStatus,_that.requestedCity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> suggestions,  Weather? weather,  WeatherSearchStatus searchStatus,  WeatherLoadStatus loadStatus,  String requestedCity)  $default,) {final _that = this;
switch (_that) {
case _WeatherState():
return $default(_that.suggestions,_that.weather,_that.searchStatus,_that.loadStatus,_that.requestedCity);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> suggestions,  Weather? weather,  WeatherSearchStatus searchStatus,  WeatherLoadStatus loadStatus,  String requestedCity)?  $default,) {final _that = this;
switch (_that) {
case _WeatherState() when $default != null:
return $default(_that.suggestions,_that.weather,_that.searchStatus,_that.loadStatus,_that.requestedCity);case _:
  return null;

}
}

}

/// @nodoc


class _WeatherState implements WeatherState {
  const _WeatherState({final  List<String> suggestions = const [], this.weather, this.searchStatus = WeatherSearchStatus.idle, this.loadStatus = WeatherLoadStatus.idle, this.requestedCity = ''}): _suggestions = suggestions;
  

 final  List<String> _suggestions;
@override@JsonKey() List<String> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}

@override final  Weather? weather;
@override@JsonKey() final  WeatherSearchStatus searchStatus;
@override@JsonKey() final  WeatherLoadStatus loadStatus;
@override@JsonKey() final  String requestedCity;

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherStateCopyWith<_WeatherState> get copyWith => __$WeatherStateCopyWithImpl<_WeatherState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherState&&const DeepCollectionEquality().equals(other._suggestions, _suggestions)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.searchStatus, searchStatus) || other.searchStatus == searchStatus)&&(identical(other.loadStatus, loadStatus) || other.loadStatus == loadStatus)&&(identical(other.requestedCity, requestedCity) || other.requestedCity == requestedCity));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_suggestions),weather,searchStatus,loadStatus,requestedCity);

@override
String toString() {
  return 'WeatherState(suggestions: $suggestions, weather: $weather, searchStatus: $searchStatus, loadStatus: $loadStatus, requestedCity: $requestedCity)';
}


}

/// @nodoc
abstract mixin class _$WeatherStateCopyWith<$Res> implements $WeatherStateCopyWith<$Res> {
  factory _$WeatherStateCopyWith(_WeatherState value, $Res Function(_WeatherState) _then) = __$WeatherStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> suggestions, Weather? weather, WeatherSearchStatus searchStatus, WeatherLoadStatus loadStatus, String requestedCity
});




}
/// @nodoc
class __$WeatherStateCopyWithImpl<$Res>
    implements _$WeatherStateCopyWith<$Res> {
  __$WeatherStateCopyWithImpl(this._self, this._then);

  final _WeatherState _self;
  final $Res Function(_WeatherState) _then;

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? suggestions = null,Object? weather = freezed,Object? searchStatus = null,Object? loadStatus = null,Object? requestedCity = null,}) {
  return _then(_WeatherState(
suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>,weather: freezed == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as Weather?,searchStatus: null == searchStatus ? _self.searchStatus : searchStatus // ignore: cast_nullable_to_non_nullable
as WeatherSearchStatus,loadStatus: null == loadStatus ? _self.loadStatus : loadStatus // ignore: cast_nullable_to_non_nullable
as WeatherLoadStatus,requestedCity: null == requestedCity ? _self.requestedCity : requestedCity // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
