// Copyright 2018-present 650 Industries. All rights reserved.

#import <ABI36_0_0EXAppleAuthentication/ABI36_0_0EXAppleAuthentication.h>
#import <ABI36_0_0EXAppleAuthentication/ABI36_0_0EXAppleAuthenticationRequest.h>
#import <ABI36_0_0EXAppleAuthentication/ABI36_0_0EXAppleAuthenticationMappings.h>

#import <ABI36_0_0UMCore/ABI36_0_0UMUtilities.h>
#import <ABI36_0_0UMCore/ABI36_0_0UMErrorCodes.h>

static NSString *const ABI36_0_0EXAppleIDCredentialRevokedEvent = @"Expo.appleIdCredentialRevoked";

@interface ABI36_0_0EXAppleAuthentication ()

@property (nonatomic, weak) ABI36_0_0UMModuleRegistry *moduleRegistry;

@end

@implementation ABI36_0_0EXAppleAuthentication

ABI36_0_0UM_EXPORT_MODULE(ExpoAppleAuthentication);

- (void)setModuleRegistry:(ABI36_0_0UMModuleRegistry *)moduleRegistry
{
  _moduleRegistry = moduleRegistry;
}

- (NSArray<NSString *> *)supportedEvents
{
  return @[ABI36_0_0EXAppleIDCredentialRevokedEvent];
}

- (void)startObserving
{
  if (@available(iOS 13.0, *)) {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRevokeCredential:)
                                                 name:ASAuthorizationAppleIDProviderCredentialRevokedNotification
                                               object:nil];
  }
}

- (void)stopObserving
{
  if (@available(iOS 13.0, *)) {
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:ASAuthorizationAppleIDProviderCredentialRevokedNotification
                                                  object:nil];
  }
}

- (void)didRevokeCredential:(NSNotification *)notification
{
  id<ABI36_0_0UMEventEmitterService> eventEmitter = [_moduleRegistry getModuleImplementingProtocol:@protocol(ABI36_0_0UMEventEmitterService)];
  [eventEmitter sendEventWithName:ABI36_0_0EXAppleIDCredentialRevokedEvent body:@{}];
}

ABI36_0_0UM_EXPORT_METHOD_AS(isAvailableAsync,
                    isAvailableAsync:(ABI36_0_0UMPromiseResolveBlock)resolve
                            rejecter:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (@available(iOS 13.0, *)) {
    resolve(@(YES));
  } else {
    resolve(@(NO));
  }
}

ABI36_0_0UM_EXPORT_METHOD_AS(requestAsync,
                    requestAsync:(NSDictionary *)options
                    resolver:(ABI36_0_0UMPromiseResolveBlock)resolve
                    rejecter:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (@available(iOS 13.0, *)) {
    [self requestWithOptions:options
                    resolver:resolve
                    rejecter:reject];
  } else {
    reject(@"ERR_APPLE_AUTHENTICATION_UNAVAILABLE", @"Apple authentication is not supported on this device.", nil);
  }
}

ABI36_0_0UM_EXPORT_METHOD_AS(getCredentialStateAsync,
                    getCredentialStateAsync:(NSString *)userID
                                   resolver:(ABI36_0_0UMPromiseResolveBlock)resolve
                                   rejecter:(ABI36_0_0UMPromiseRejectBlock)reject)
{
  if (@available(iOS 13.0, *)) {
    ASAuthorizationAppleIDProvider *appleIDProvider = [[ASAuthorizationAppleIDProvider alloc] init];
    [appleIDProvider getCredentialStateForUserID:userID
                                      completion:^(ASAuthorizationAppleIDProviderCredentialState credentialState,
                                                   NSError  *_Nullable error) {
      if (error) {
        return reject(@"ERR_APPLE_AUTHENTICATION_CREDENTIAL", error.localizedDescription, nil);
      }
      resolve([ABI36_0_0EXAppleAuthenticationMappings exportCredentialState:credentialState]);
    }];
  } else {
    reject(@"ERR_APPLE_AUTHENTICATION_UNAVAILABLE", @"Apple authentication is not supported on this device.", nil);
  }
}

#pragma mark - helpers

- (void)requestWithOptions:(NSDictionary *)options
                  resolver:(ABI36_0_0UMPromiseResolveBlock)resolve
                  rejecter:(ABI36_0_0UMPromiseRejectBlock)reject API_AVAILABLE(ios(13.0))
{
  ASAuthorizationProviderAuthorizationOperation operation = [ABI36_0_0EXAppleAuthenticationMappings importOperation:options[@"requestedOperation"]];
  __block ABI36_0_0EXAppleAuthenticationRequest *request = [ABI36_0_0EXAppleAuthenticationRequest performOperation:operation
                                                                                     withOptions:options
                                                                                    withCallback:^(NSDictionary *response, NSError *error) {
    if (error) {
      if (error.code == 1001) {
        // User canceled authentication attempt.
        reject(ABI36_0_0UMErrorCodeCanceled, @"The Apple authentication request has been canceled by the user.", nil);
      } else {
        reject(@"ERR_APPLE_AUTHENTICATION_REQUEST_FAILED", error.localizedDescription, nil);
      }
    } else {
      resolve(response);
    }
    request = nil;
  }];
}

@end