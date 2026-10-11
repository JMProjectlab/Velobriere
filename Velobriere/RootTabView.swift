import SwiftUI
#if canImport(FirebaseFirestore)
import FirebaseAuth
#endif

struct RootTabView: View {
    enum Tab: Hashable {
        case home, catalog, reservations, legal
    }

    @StateObject private var reservationStore = ReservationStore()
    @StateObject private var invoiceStore = InvoiceStore()
    @StateObject private var session = AccountSession()
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(bike: BikeCatalog.eActv100) { selectedTab = $0 }
                .tabItem {
                    Label("Accueil", systemImage: "house")
                }
                .tag(Tab.home)

            CatalogView(bikes: BikeCatalog.all)
                .tabItem {
                    Label("Vélos", systemImage: "bicycle")
                }
                .tag(Tab.catalog)

            MyReservationsView()
                .tabItem {
                    Label("Réservations", systemImage: "calendar")
                }
                .tag(Tab.reservations)

            LegalInfoView()
                .tabItem {
                    Label("Informations", systemImage: "info.circle")
                }
                .tag(Tab.legal)
        }
        .tint(Theme.Colors.primary)
        .environmentObject(reservationStore)
        .environmentObject(invoiceStore)
        .environmentObject(session)
    }
}

// MARK: - Compte
//
// Tout ce qui suit vit dans ce fichier plutôt que dans des fichiers dédiés
// parce que le projet Xcode référence ses sources une par une : un fichier neuf
// ne serait pas compilé tant qu'il n'a pas été ajouté à la cible à la main.
// À déplacer le jour où le projet passera aux groupes synchronisés.

/// État de connexion, publié pour que les écrans réagissent.
///
/// Sans le paquet Firebase, cet objet existe quand même mais reste vide : les
/// écrans affichent « mode local » et l'application se comporte comme avant.
@MainActor
final class AccountSession: ObservableObject {
    @Published private(set) var email: String?
    @Published private(set) var uid: String?

    var estConnecte: Bool { uid != nil }

    init() {
        #if canImport(FirebaseFirestore)
        guard FirebaseSupport.isAvailable else { return }
        // `addStateDidChangeListener` se déclenche immédiatement avec la session
        // restaurée, s'il y en a une : rien à recharger à la main au démarrage.
        Auth.auth().addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor in
                self?.uid = user?.uid
                self?.email = user?.email
            }
        }
        #endif
    }

    /// Vrai quand un compte est possible : Firebase est configuré.
    var comptesDisponibles: Bool {
        #if canImport(FirebaseFirestore)
        return FirebaseSupport.isAvailable
        #else
        return false
        #endif
    }

    func creerCompte(email: String, motDePasse: String) async throws {
        #if canImport(FirebaseFirestore)
        _ = try await Auth.auth().createUser(withEmail: email, password: motDePasse)
        #else
        throw ReservationError.remote("La synchronisation n'est pas disponible sur cette version.")
        #endif
    }

    func seConnecter(email: String, motDePasse: String) async throws {
        #if canImport(FirebaseFirestore)
        _ = try await Auth.auth().signIn(withEmail: email, password: motDePasse)
        #else
        throw ReservationError.remote("La synchronisation n'est pas disponible sur cette version.")
        #endif
    }

    func seDeconnecter() throws {
        #if canImport(FirebaseFirestore)
        try Auth.auth().signOut()
        #endif
    }

    /// Traduit les erreurs Firebase. À la connexion, le message est le même
    /// quelle que soit la cause : ne pas révéler si l'adresse existe.
    static func message(for error: Error, connexion: Bool) -> String {
        #if canImport(FirebaseFirestore)
        let code = AuthErrorCode(rawValue: (error as NSError).code)
        if connexion {
            if code == .tooManyRequests {
                return "Trop de tentatives. Réessayez dans quelques minutes."
            }
            return "Adresse e-mail ou mot de passe incorrect."
        }
        switch code {
        case .emailAlreadyInUse:
            return "Un compte existe déjà avec cette adresse. Connectez-vous plutôt."
        case .invalidEmail:
            return "L'adresse e-mail n'est pas valide."
        case .weakPassword:
            return "Le mot de passe est trop court."
        case .networkError:
            return "Connexion au serveur impossible. Vérifiez votre accès à Internet."
        default:
            return error.localizedDescription
        }
        #else
        return error.localizedDescription
        #endif
    }
}

/// Connexion et création de compte.
///
/// **Le compte reste facultatif.** Réserver, consulter ses réservations et
/// annuler fonctionnent sans, en local — comme l'exige la règle 5.1.1(v) de
/// l'App Store, et comme le bon sens le veut : compter des vélos n'a pas besoin
/// d'une identité. Le compte apporte une seule chose, mais elle est décisive :
/// les réservations deviennent partagées, donc le loueur les voit.
struct AccountView: View {
    @EnvironmentObject private var session: AccountSession
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var motDePasse = ""
    @State private var creation = false
    @State private var enCours = false
    @State private var erreur: String?

    private var champsValides: Bool {
        email.contains("@") && motDePasse.count >= 8
    }

    var body: some View {
        NavigationStack {
            Form {
                if session.estConnecte {
                    Section("Compte") {
                        HStack {
                            Text("Connecté")
                            Spacer()
                            Text(session.email ?? "").foregroundStyle(Theme.Colors.inkSoft)
                        }
                        Text("Vos réservations sont enregistrées chez le loueur et vous suivent sur vos autres appareils.")
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.inkSoft)
                        Button(role: .destructive) {
                            try? session.seDeconnecter()
                        } label: {
                            Text("Se déconnecter")
                        }
                    }
                } else if session.comptesDisponibles {
                    Section(creation ? "Créer un compte" : "Se connecter") {
                        TextField("Adresse e-mail", text: $email)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                        SecureField("Mot de passe (8 caractères minimum)", text: $motDePasse)

                        PrimaryButton(title: creation ? "Créer mon compte" : "Se connecter",
                                      isDisabled: !champsValides || enCours) {
                            valider()
                        }

                        Button(creation
                               ? "J'ai déjà un compte"
                               : "Créer un compte") {
                            creation.toggle()
                            erreur = nil
                        }
                        .font(.footnote)
                    }

                    if let erreur {
                        Section {
                            Text(erreur).foregroundStyle(Theme.Colors.warning)
                        }
                    }

                    Section {
                        Text("Le compte est facultatif : vous pouvez réserver sans. Il sert à retrouver vos réservations sur vos autres appareils et à les transmettre au loueur.")
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.inkSoft)
                    }
                } else {
                    Section {
                        Text("La synchronisation n'est pas configurée sur cette version. Vos réservations restent sur cet appareil.")
                            .font(.footnote)
                            .foregroundStyle(Theme.Colors.inkSoft)
                    }
                }
            }
            .navigationTitle("Mon compte")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }

    private func valider() {
        enCours = true
        erreur = nil
        Task {
            do {
                if creation {
                    try await session.creerCompte(email: email, motDePasse: motDePasse)
                } else {
                    try await session.seConnecter(email: email, motDePasse: motDePasse)
                }
                enCours = false
                dismiss()
            } catch {
                enCours = false
                erreur = AccountSession.message(for: error, connexion: !creation)
            }
        }
    }
}
