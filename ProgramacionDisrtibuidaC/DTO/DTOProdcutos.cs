namespace ProgramacionDisrtibuidaC.DTO
{
    public class DTOProductos
    {
        public int Id { get; set; }

        public string Name { get; set; } = "";

        public decimal Price { get; set; }

        public int Stock { get; set; }

        public string Description { get; set; } = "";

        public string ImageUrl { get; set; } = "";

        public bool IsActive { get; set; }

        public string Versions { get; set; } = "";
    }
}