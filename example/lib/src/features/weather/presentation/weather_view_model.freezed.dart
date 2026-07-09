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

 List<String> get suggestions; Weather? get weather; bool get isLoading;
/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherStateCopyWith<WeatherState> get copyWith => _$WeatherStateCopyWithImpl<WeatherState>(this as WeatherState, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherState&&const DeepCollectionEquality().equals(other.suggestions, suggestions)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(suggestions),weather,isLoading);

@override
String toString() {
  return 'WeatherState(suggestions: $suggestions, weather: $weather, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class $WeatherStateCopyWith<$Res>  {
  factory $WeatherStateCopyWith(WeatherState value, $Res Function(WeatherState) _then) = _$WeatherStateCopyWithImpl;
@useResult
$Res call({
 List<String> suggestions, Weather? weather, bool isLoading
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
@pragma('vm:prefer-inline') @override $Res call({Object? suggestions = null,Object? weather = freezed,Object? isLoading = null,}) {
  return _then(_self.copyWith(
suggestions: null == suggestions ? _self.suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>,weather: freezed == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as Weather?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<String> suggestions,  Weather? weather,  bool isLoading)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeatherState() when $default != null:
return $default(_that.suggestions,_that.weather,_that.isLoading);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<String> suggestions,  Weather? weather,  bool isLoading)  $default,) {final _that = this;
switch (_that) {
case _WeatherState():
return $default(_that.suggestions,_that.weather,_that.isLoading);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<String> suggestions,  Weather? weather,  bool isLoading)?  $default,) {final _that = this;
switch (_that) {
case _WeatherState() when $default != null:
return $default(_that.suggestions,_that.weather,_that.isLoading);case _:
  return null;

}
}

}

/// @nodoc


class _WeatherState implements WeatherState {
  const _WeatherState({final  List<String> suggestions = const [], this.weather, this.isLoading = false}): _suggestions = suggestions;
  

 final  List<String> _suggestions;
@override@JsonKey() List<String> get suggestions {
  if (_suggestions is EqualUnmodifiableListView) return _suggestions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_suggestions);
}

@override final  Weather? weather;
@override@JsonKey() final  bool isLoading;

/// Create a copy of WeatherState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeatherStateCopyWith<_WeatherState> get copyWith => __$WeatherStateCopyWithImpl<_WeatherState>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeatherState&&const DeepCollectionEquality().equals(other._suggestions, _suggestions)&&(identical(other.weather, weather) || other.weather == weather)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_suggestions),weather,isLoading);

@override
String toString() {
  return 'WeatherState(suggestions: $suggestions, weather: $weather, isLoading: $isLoading)';
}


}

/// @nodoc
abstract mixin class _$WeatherStateCopyWith<$Res> implements $WeatherStateCopyWith<$Res> {
  factory _$WeatherStateCopyWith(_WeatherState value, $Res Function(_WeatherState) _then) = __$WeatherStateCopyWithImpl;
@override @useResult
$Res call({
 List<String> suggestions, Weather? weather, bool isLoading
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
@override @pragma('vm:prefer-inline') $Res call({Object? suggestions = null,Object? weather = freezed,Object? isLoading = null,}) {
  return _then(_WeatherState(
suggestions: null == suggestions ? _self._suggestions : suggestions // ignore: cast_nullable_to_non_nullable
as List<String>,weather: freezed == weather ? _self.weather : weather // ignore: cast_nullable_to_non_nullable
as Weather?,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc
mixin _$WeatherEffect {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherEffect);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WeatherEffect()';
}


}

/// @nodoc
class $WeatherEffectCopyWith<$Res>  {
$WeatherEffectCopyWith(WeatherEffect _, $Res Function(WeatherEffect) __);
}


/// Adds pattern-matching-related methods to [WeatherEffect].
extension WeatherEffectPatterns on WeatherEffect {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( WeatherEmptyCity value)?  emptyCity,TResult Function( WeatherLocationNotFound value)?  locationNotFound,TResult Function( WeatherServiceFailed value)?  serviceFailed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case WeatherEmptyCity() when emptyCity != null:
return emptyCity(_that);case WeatherLocationNotFound() when locationNotFound != null:
return locationNotFound(_that);case WeatherServiceFailed() when serviceFailed != null:
return serviceFailed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( WeatherEmptyCity value)  emptyCity,required TResult Function( WeatherLocationNotFound value)  locationNotFound,required TResult Function( WeatherServiceFailed value)  serviceFailed,}){
final _that = this;
switch (_that) {
case WeatherEmptyCity():
return emptyCity(_that);case WeatherLocationNotFound():
return locationNotFound(_that);case WeatherServiceFailed():
return serviceFailed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( WeatherEmptyCity value)?  emptyCity,TResult? Function( WeatherLocationNotFound value)?  locationNotFound,TResult? Function( WeatherServiceFailed value)?  serviceFailed,}){
final _that = this;
switch (_that) {
case WeatherEmptyCity() when emptyCity != null:
return emptyCity(_that);case WeatherLocationNotFound() when locationNotFound != null:
return locationNotFound(_that);case WeatherServiceFailed() when serviceFailed != null:
return serviceFailed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  emptyCity,TResult Function( String city)?  locationNotFound,TResult Function( String message)?  serviceFailed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case WeatherEmptyCity() when emptyCity != null:
return emptyCity();case WeatherLocationNotFound() when locationNotFound != null:
return locationNotFound(_that.city);case WeatherServiceFailed() when serviceFailed != null:
return serviceFailed(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  emptyCity,required TResult Function( String city)  locationNotFound,required TResult Function( String message)  serviceFailed,}) {final _that = this;
switch (_that) {
case WeatherEmptyCity():
return emptyCity();case WeatherLocationNotFound():
return locationNotFound(_that.city);case WeatherServiceFailed():
return serviceFailed(_that.message);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  emptyCity,TResult? Function( String city)?  locationNotFound,TResult? Function( String message)?  serviceFailed,}) {final _that = this;
switch (_that) {
case WeatherEmptyCity() when emptyCity != null:
return emptyCity();case WeatherLocationNotFound() when locationNotFound != null:
return locationNotFound(_that.city);case WeatherServiceFailed() when serviceFailed != null:
return serviceFailed(_that.message);case _:
  return null;

}
}

}

/// @nodoc


class WeatherEmptyCity implements WeatherEffect {
  const WeatherEmptyCity();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherEmptyCity);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'WeatherEffect.emptyCity()';
}


}




/// @nodoc


class WeatherLocationNotFound implements WeatherEffect {
  const WeatherLocationNotFound(this.city);
  

 final  String city;

/// Create a copy of WeatherEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherLocationNotFoundCopyWith<WeatherLocationNotFound> get copyWith => _$WeatherLocationNotFoundCopyWithImpl<WeatherLocationNotFound>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherLocationNotFound&&(identical(other.city, city) || other.city == city));
}


@override
int get hashCode => Object.hash(runtimeType,city);

@override
String toString() {
  return 'WeatherEffect.locationNotFound(city: $city)';
}


}

/// @nodoc
abstract mixin class $WeatherLocationNotFoundCopyWith<$Res> implements $WeatherEffectCopyWith<$Res> {
  factory $WeatherLocationNotFoundCopyWith(WeatherLocationNotFound value, $Res Function(WeatherLocationNotFound) _then) = _$WeatherLocationNotFoundCopyWithImpl;
@useResult
$Res call({
 String city
});




}
/// @nodoc
class _$WeatherLocationNotFoundCopyWithImpl<$Res>
    implements $WeatherLocationNotFoundCopyWith<$Res> {
  _$WeatherLocationNotFoundCopyWithImpl(this._self, this._then);

  final WeatherLocationNotFound _self;
  final $Res Function(WeatherLocationNotFound) _then;

/// Create a copy of WeatherEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? city = null,}) {
  return _then(WeatherLocationNotFound(
null == city ? _self.city : city // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class WeatherServiceFailed implements WeatherEffect {
  const WeatherServiceFailed(this.message);
  

 final  String message;

/// Create a copy of WeatherEffect
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeatherServiceFailedCopyWith<WeatherServiceFailed> get copyWith => _$WeatherServiceFailedCopyWithImpl<WeatherServiceFailed>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeatherServiceFailed&&(identical(other.message, message) || other.message == message));
}


@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'WeatherEffect.serviceFailed(message: $message)';
}


}

/// @nodoc
abstract mixin class $WeatherServiceFailedCopyWith<$Res> implements $WeatherEffectCopyWith<$Res> {
  factory $WeatherServiceFailedCopyWith(WeatherServiceFailed value, $Res Function(WeatherServiceFailed) _then) = _$WeatherServiceFailedCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$WeatherServiceFailedCopyWithImpl<$Res>
    implements $WeatherServiceFailedCopyWith<$Res> {
  _$WeatherServiceFailedCopyWithImpl(this._self, this._then);

  final WeatherServiceFailed _self;
  final $Res Function(WeatherServiceFailed) _then;

/// Create a copy of WeatherEffect
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(WeatherServiceFailed(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
