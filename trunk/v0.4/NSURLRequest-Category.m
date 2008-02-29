// this is kind of a hack job to allow bad certs

@implementation NSURLRequest(NSHTTPURLRequestFix)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString *)host
{
	ENTRY(( @"entered +allowsAnyHTTPSCertificateForHost: %@", host ));
	//might want to allow for a preference instead of assuming yes
	return YES; // Or whatever logic
}

@end
